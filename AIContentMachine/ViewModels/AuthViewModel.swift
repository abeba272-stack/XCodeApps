import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isRegistering = false
    @Published var isBusy = false
    @Published var errorMessage: String?

    private let sessionManager: UserSessionManager
    init(sessionManager: UserSessionManager) {
        self.sessionManager = sessionManager
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

    var isGoogleSignInEnabled: Bool {
        AuthProviderAvailability.googleSignInEnabled
    }

    var showsQuickSignIn: Bool {
        isGoogleSignInEnabled
    }

    var providerAvailabilityMessage: String {
        if showsQuickSignIn {
            return "Only providers that are fully configured for this build are shown."
        }
        return "This local build uses email and password as the main path. Apple and Google can be enabled later once external setup is finished."
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

    func handleGoogleSignIn() async {
        isBusy = true
        defer { isBusy = false }

        await sessionManager.signInWithGoogle()
        errorMessage = sessionManager.errorMessage
    }
}
