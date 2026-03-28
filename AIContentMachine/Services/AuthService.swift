import AuthenticationServices
import CryptoKit
import Foundation
import SwiftData

@MainActor
protocol AuthService: AnyObject {
    func restoreCurrentUser() throws -> UserProfile?
    func register(email: String, password: String) throws -> UserProfile
    func signIn(email: String, password: String) throws -> UserProfile
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) throws -> UserProfile
    func signInWithGoogle() async throws -> UserProfile
    func signOut() throws
    func syncSubscriptionPlan(for user: UserProfile?, hasProAccess: Bool) throws
}

protocol UserPreferencesService {
    func promptContext(for user: UserProfile) -> String
}

struct DefaultUserPreferencesService: UserPreferencesService {
    func promptContext(for user: UserProfile) -> String {
        user.promptContextBlock
    }
}

@MainActor
final class SwiftDataAuthService: AuthService {
    private let modelContainer: ModelContainer
    private let logger: any AppLogger

    init(modelContainer: ModelContainer, logger: any AppLogger) {
        self.modelContainer = modelContainer
        self.logger = logger
    }

    func restoreCurrentUser() throws -> UserProfile? {
        let context = modelContainer.mainContext
        let settings = try loadOrCreateSettings(in: context)

        if let currentUserID = settings.currentUserID,
           let currentUser = try fetchUser(id: currentUserID, in: context) {
            currentUser.lastSignedInAt = .now
            try context.save()
            return currentUser
        }

        if let migrated = try migrateLegacyProfileIfNeeded(settings: settings, context: context) {
            return migrated
        }

        settings.currentUserID = nil
        try context.save()
        return nil
    }

    func register(email: String, password: String) throws -> UserProfile {
        let normalizedEmail = sanitize(email)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(normalizedEmail) else {
            throw AppError.validation("Enter a valid email address.")
        }

        guard trimmedPassword.count >= 8 else {
            throw AppError.validation("Use at least 8 characters for the password.")
        }

        let context = modelContainer.mainContext
        let settings = try loadOrCreateSettings(in: context)

        if try fetchUser(email: normalizedEmail, in: context) != nil {
            throw AppError.validation("An account with this email already exists.")
        }

        let user = UserProfile(
            creatorName: defaultCreatorName(for: normalizedEmail),
            email: normalizedEmail,
            passwordHash: Self.hashPassword(trimmedPassword, email: normalizedEmail),
            authProvider: .email,
            subscriptionPlan: .standard,
            createdAt: .now,
            lastSignedInAt: .now
        )

        context.insert(user)
        settings.currentUserID = user.id
        try save(context, fallback: "The account could not be created.")
        return user
    }

    func signIn(email: String, password: String) throws -> UserProfile {
        let normalizedEmail = sanitize(email)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedEmail.isEmpty, !trimmedPassword.isEmpty else {
            throw AppError.validation("Enter your email and password to continue.")
        }

        if isDebugSpecialProLogin(email: normalizedEmail, password: trimmedPassword) {
            return try upsertSpecialUser()
        }

        let context = modelContainer.mainContext
        let settings = try loadOrCreateSettings(in: context)

        guard let user = try fetchUser(email: normalizedEmail, in: context) else {
            throw AppError.validation("No account was found for this email.")
        }

        guard user.hasPasswordLogin else {
            throw AppError.validation("This account uses another sign-in method.")
        }

        let attemptedHash = Self.hashPassword(trimmedPassword, email: normalizedEmail)
        guard attemptedHash == user.passwordHash else {
            throw AppError.validation("The password is incorrect.")
        }

        user.lastSignedInAt = .now
        settings.currentUserID = user.id
        try save(context, fallback: "The account session could not be restored.")
        return user
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) throws -> UserProfile {
        let context = modelContainer.mainContext
        let settings = try loadOrCreateSettings(in: context)
        let appleUserID = credential.user
        let resolvedEmail = sanitize(credential.email ?? "")

        let user = try fetchUser(appleUserID: appleUserID, in: context)
            ?? fetchOrCreateAppleUser(email: resolvedEmail, appleUserID: appleUserID, credential: credential, context: context)

        user.authProvider = .apple
        user.appleUserID = appleUserID
        if user.email.isEmpty {
            user.email = resolvedEmail.isEmpty ? "apple-\(appleUserID.prefix(8))@local.aicontentmachine" : resolvedEmail
        }
        if user.creatorName == "Creator" || user.creatorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let formattedName = PersonNameComponentsFormatter().string(from: credential.fullName ?? PersonNameComponents())
            user.creatorName = formattedName.isEmpty ? defaultCreatorName(for: user.email) : formattedName
        }
        user.lastSignedInAt = .now

        settings.currentUserID = user.id
        try save(context, fallback: "Sign in with Apple could not be completed.")
        return user
    }

    func signInWithGoogle() async throws -> UserProfile {
        if !GoogleIdentityConfiguration.isConfigured {
            throw AppError.validation("Google Sign-In is not configured yet. Add the iOS client ID and callback scheme first.")
        }

        throw AppError.validation("Google Sign-In is prepared in the app structure, but the OAuth client setup still needs to be completed for this build.")
    }

    func signOut() throws {
        let context = modelContainer.mainContext
        let settings = try loadOrCreateSettings(in: context)
        settings.currentUserID = nil
        try save(context, fallback: "The current session could not be cleared.")
    }

    func syncSubscriptionPlan(for user: UserProfile?, hasProAccess: Bool) throws {
        guard let user else { return }
        guard !user.isSpecialProUser else {
            if user.subscriptionPlan != .pro {
                user.subscriptionPlan = .pro
                try save(modelContainer.mainContext, fallback: "The special account plan could not be refreshed.")
            }
            return
        }

        let expectedPlan: SubscriptionPlan = hasProAccess ? .pro : .standard
        guard user.subscriptionPlan != expectedPlan else { return }

        user.subscriptionPlan = expectedPlan
        try save(modelContainer.mainContext, fallback: "The account subscription state could not be refreshed.")
    }

    private func fetchUser(id: UUID, in context: ModelContext) throws -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { user in
                user.id == id
            }
        )
        return try context.fetch(descriptor).first
    }

    private func fetchUser(email: String, in context: ModelContext) throws -> UserProfile? {
        let users = try context.fetch(FetchDescriptor<UserProfile>())
        return users.first(where: { $0.normalizedEmail == email })
    }

    private func fetchUser(appleUserID: String, in context: ModelContext) throws -> UserProfile? {
        let users = try context.fetch(FetchDescriptor<UserProfile>())
        return users.first(where: { $0.appleUserID == appleUserID })
    }

    private func fetchOrCreateAppleUser(email: String, appleUserID: String, credential: ASAuthorizationAppleIDCredential, context: ModelContext) throws -> UserProfile {
        if !email.isEmpty, let existingByEmail = try fetchUser(email: email, in: context) {
            return existingByEmail
        }

        let formattedName = PersonNameComponentsFormatter().string(from: credential.fullName ?? PersonNameComponents())
        let fallbackEmail = email.isEmpty ? "apple-\(appleUserID.prefix(8))@local.aicontentmachine" : email

        let user = UserProfile(
            creatorName: formattedName.isEmpty ? defaultCreatorName(for: fallbackEmail) : formattedName,
            email: fallbackEmail,
            authProvider: .apple,
            subscriptionPlan: .standard,
            createdAt: .now,
            lastSignedInAt: .now,
            appleUserID: appleUserID
        )
        context.insert(user)
        return user
    }

    private func upsertSpecialUser() throws -> UserProfile {
#if DEBUG
        let context = modelContainer.mainContext
        let settings = try loadOrCreateSettings(in: context)
        let email = AuthConstants.specialProEmail.lowercased()

        let user = try fetchUser(email: email, in: context) ?? {
            let newUser = UserProfile(
                creatorName: "Abeba",
                email: email,
                passwordHash: Self.hashPassword(AuthConstants.specialProPassword, email: email),
                authProvider: .special,
                subscriptionPlan: .pro,
                createdAt: .now,
                lastSignedInAt: .now,
                isSpecialProUser: true
            )
            context.insert(newUser)
            return newUser
        }()

        user.email = email
        user.passwordHash = Self.hashPassword(AuthConstants.specialProPassword, email: email)
        user.authProvider = .special
        user.subscriptionPlan = .pro
        user.isSpecialProUser = true
        user.lastSignedInAt = .now

        settings.currentUserID = user.id
        try save(context, fallback: "The special Pro account could not be activated.")
        return user
#else
        throw AppError.validation("The special Pro account is only available in local debug builds.")
#endif
    }

    private func migrateLegacyProfileIfNeeded(settings: AppSettings, context: ModelContext) throws -> UserProfile? {
        let users = try context.fetch(FetchDescriptor<UserProfile>())
        guard users.count == 1, let legacyUser = users.first else { return nil }
        guard !legacyUser.hasAuthIdentity else { return nil }

        legacyUser.authProvider = .deviceMigration
        legacyUser.subscriptionPlan = .standard
        legacyUser.lastSignedInAt = .now
        if legacyUser.defaultAudience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            legacyUser.defaultAudience = "Creators who want better short-form content"
        }

        settings.currentUserID = legacyUser.id
        try save(context, fallback: "The existing local profile could not be migrated into the new account system.")
        return legacyUser
    }

    private func loadOrCreateSettings(in context: ModelContext) throws -> AppSettings {
        if let existing = try context.fetch(FetchDescriptor<AppSettings>()).first {
            return existing
        }

        let settings = AppSettings()
        context.insert(settings)
        try save(context, fallback: "The app settings could not be initialized.")
        return settings
    }

    private func save(_ context: ModelContext, fallback: String) throws {
        do {
            try context.save()
        } catch {
            logger.error("Auth service persistence failed: \(error.localizedDescription)", category: "AuthService")
            throw AppError.persistence(fallback)
        }
    }

    private func sanitize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }

    private func defaultCreatorName(for email: String) -> String {
        let base = email.split(separator: "@").first.map(String.init) ?? "Creator"
        let cleaned = base.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "_", with: " ")
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Creator" : trimmed.capitalized
    }

    private func isDebugSpecialProLogin(email: String, password: String) -> Bool {
#if DEBUG
        email == AuthConstants.specialProEmail.lowercased() && password == AuthConstants.specialProPassword
#else
        false
#endif
    }

    static func hashPassword(_ password: String, email: String) -> String {
        let source = "\(email.lowercased())::\(password)"
        let digest = SHA256.hash(data: Data(source.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

@MainActor
final class UserSessionManager: ObservableObject {
    @Published private(set) var currentUser: UserProfile?
    @Published private(set) var isLoggedIn = false
    @Published private(set) var hasResolvedInitialSession = false
    @Published private(set) var isBusy = false
    @Published var errorMessage: String?

    private let authService: any AuthService
    private let subscriptionStore: SubscriptionStore
    private let logger: any AppLogger

    init(authService: any AuthService, subscriptionStore: SubscriptionStore, logger: any AppLogger) {
        self.authService = authService
        self.subscriptionStore = subscriptionStore
        self.logger = logger
    }

    var hasProAccess: Bool {
        currentUser?.isSpecialProUser == true || subscriptionStore.isPro
    }

    var currentPlan: SubscriptionPlan {
        hasProAccess ? .pro : .standard
    }

    var accountEmail: String {
        currentUser?.email ?? ""
    }

    func restoreSessionIfNeeded() async {
        guard !hasResolvedInitialSession else { return }
        isBusy = true
        defer {
            isBusy = false
            hasResolvedInitialSession = true
        }

        do {
            let user = try authService.restoreCurrentUser()
            completeSession(with: user)
            try authService.syncSubscriptionPlan(for: user, hasProAccess: subscriptionStore.hasActiveSubscription)
            if let user {
                currentUser = user
            }
            errorMessage = nil
        } catch {
            logger.error("Restoring user session failed: \(error.localizedDescription)", category: "UserSessionManager")
            errorMessage = AppError.from(error, fallback: "The account session could not be restored.").localizedDescription
        }
    }

    func register(email: String, password: String) async {
        await performAuthAction {
            try authService.register(email: email, password: password)
        }
    }

    func signIn(email: String, password: String) async {
        await performAuthAction {
            try authService.signIn(email: email, password: password)
        }
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        await performAuthAction {
            try authService.signInWithApple(credential: credential)
        }
    }

    func signInWithGoogle() async {
        await performAsyncAuthAction {
            try await authService.signInWithGoogle()
        }
    }

    func signOut() {
        do {
            try authService.signOut()
            subscriptionStore.setSpecialUserProOverride(false)
            currentUser = nil
            isLoggedIn = false
            errorMessage = nil
        } catch {
            logger.error("Signing out failed: \(error.localizedDescription)", category: "UserSessionManager")
            errorMessage = AppError.from(error, fallback: "The account could not be signed out.").localizedDescription
        }
    }

    func syncSubscriptionState() {
        do {
            subscriptionStore.setSpecialUserProOverride(currentUser?.isSpecialProUser == true)
            try authService.syncSubscriptionPlan(for: currentUser, hasProAccess: subscriptionStore.hasActiveSubscription)
            if let currentUser {
                self.currentUser = currentUser
            }
        } catch {
            logger.error("Syncing subscription plan failed: \(error.localizedDescription)", category: "UserSessionManager")
            errorMessage = AppError.from(error, fallback: "The account plan could not be refreshed.").localizedDescription
        }
    }

    private func performAuthAction(_ action: () throws -> UserProfile) async {
        isBusy = true
        defer { isBusy = false }

        do {
            let user = try action()
            completeSession(with: user)
            try authService.syncSubscriptionPlan(for: user, hasProAccess: subscriptionStore.hasActiveSubscription)
            currentUser = user
            errorMessage = nil
        } catch {
            logger.error("Auth flow failed: \(error.localizedDescription)", category: "UserSessionManager")
            errorMessage = AppError.from(error, fallback: "The account action could not be completed.").localizedDescription
        }
    }

    private func performAsyncAuthAction(_ action: () async throws -> UserProfile) async {
        isBusy = true
        defer { isBusy = false }

        do {
            let user = try await action()
            completeSession(with: user)
            try authService.syncSubscriptionPlan(for: user, hasProAccess: subscriptionStore.hasActiveSubscription)
            currentUser = user
            errorMessage = nil
        } catch {
            logger.error("Async auth flow failed: \(error.localizedDescription)", category: "UserSessionManager")
            errorMessage = AppError.from(error, fallback: "The account action could not be completed.").localizedDescription
        }
    }

    private func completeSession(with user: UserProfile?) {
        currentUser = user
        isLoggedIn = user != nil
        subscriptionStore.setSpecialUserProOverride(user?.isSpecialProUser == true)
    }
}
