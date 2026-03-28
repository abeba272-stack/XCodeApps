import AuthenticationServices
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isRegistering = false
    @Published var isBusy = false
    @Published var errorMessage: String?

    private let sessionManager: UserSessionManager
    private let logger: any AppLogger

    init(sessionManager: UserSessionManager, logger: any AppLogger) {
        self.sessionManager = sessionManager
        self.logger = logger
    }

    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isBusy
    }

    var googleButtonSubtitle: String {
        AuthProviderAvailability.googleSignInEnabled
            ? "Use your Google account"
            : "Add Google OAuth config to enable"
    }

    var isAppleSignInEnabled: Bool {
        AuthProviderAvailability.appleSignInEnabled
    }

    var isGoogleSignInEnabled: Bool {
        AuthProviderAvailability.googleSignInEnabled
    }

    var showsQuickSignIn: Bool {
        isAppleSignInEnabled || isGoogleSignInEnabled
    }

    var providerAvailabilityMessage: String {
        if showsQuickSignIn {
            return "Only providers that are fully configured for this build are shown."
        }
        return "This local build uses email and password as the main path. Apple and Google can be enabled later once external setup is finished."
    }

    var appleButtonSubtitle: String {
        isAppleSignInEnabled
            ? "Use your Apple account"
            : "Enable Apple Developer setup later to turn this on"
    }

    func submit() async {
        guard canSubmit else { return }
        isBusy = true
        defer { isBusy = false }

        if isRegistering {
            await sessionManager.register(email: email, password: password)
        } else {
            await sessionManager.signIn(email: email, password: password)
        }

        errorMessage = sessionManager.errorMessage
    }

    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        isBusy = true
        defer { isBusy = false }

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Apple Sign-In returned an invalid credential."
                return
            }
            await sessionManager.signInWithApple(credential: credential)
        case .failure(let error):
            logger.error("Apple sign-in failed: \(error.localizedDescription)", category: "AuthViewModel")
            errorMessage = AppError.from(error, fallback: "Apple Sign-In could not be completed.").localizedDescription
            return
        }

        errorMessage = sessionManager.errorMessage
    }

    func handleGoogleSignIn() async {
        isBusy = true
        defer { isBusy = false }

        await sessionManager.signInWithGoogle()
        errorMessage = sessionManager.errorMessage
    }
}
