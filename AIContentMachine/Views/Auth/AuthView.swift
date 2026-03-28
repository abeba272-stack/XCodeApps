import AuthenticationServices
import SwiftUI

struct AuthView: View {
    let container: AppContainer

    @StateObject private var viewModel: AuthViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: container.makeAuthViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 28)
                heroCard
                credentialsCard
                if viewModel.showsQuickSignIn {
                    providerCard
                } else {
                    localBuildNote
                }
                footerNote
            }
            .padding(AppTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .alert("Account", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var heroCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.accentGradient)
                        .frame(width: 58, height: 58)
                        .overlay {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color.black.opacity(0.84))
                        }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back to your creator system")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Sign in once, keep your workflow, prompt context, and Pro access tied to your account.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                Text("Your saved account context will keep recurring creator details out of the prompt form and inside the system where they belong.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(14)
                    .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            }
        }
    }

    private var credentialsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(
                    title: viewModel.isRegistering ? "Create account" : "Sign in",
                    subtitle: viewModel.isRegistering
                        ? "Register with email and password for a local-first account on this device."
                        : "Use your email and password to enter the app. Extra sign-in providers can be turned on later.",
                    eyebrow: "Account"
                )

                Picker("Mode", selection: $viewModel.isRegistering) {
                    Text("Login").tag(false)
                    Text("Register").tag(true)
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Email")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    TextField("name@example.com", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .premiumInputStyle()
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Password")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    SecureField(viewModel.isRegistering ? "At least 8 characters" : "Your password", text: $viewModel.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .premiumInputStyle()
                }

                Button {
                    Task { await viewModel.submit() }
                } label: {
                    if viewModel.isBusy {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(viewModel.isRegistering ? "Create Account" : "Sign In")
                    }
                }
                .buttonStyle(AppPrimaryButtonStyle())
                .disabled(!viewModel.canSubmit)
                .opacity(viewModel.canSubmit ? 1 : 0.72)
            }
        }
    }

    private var providerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(
                    title: "Quick sign in",
                    subtitle: "Use a connected identity provider when it is fully configured for this build.",
                    eyebrow: "Identity"
                )

                if viewModel.isAppleSignInEnabled {
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task { await viewModel.handleAppleCompletion(result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))

                    Text(viewModel.appleButtonSubtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)
                        .padding(.top, -6)
                }

                if viewModel.isGoogleSignInEnabled {
                    Button {
                        Task { await viewModel.handleGoogleSignIn() }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 16, weight: .bold))
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Continue with Google")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                Text(viewModel.googleButtonSubtitle)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(AppSecondaryButtonStyle())
                }

                Text(viewModel.providerAvailabilityMessage)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
    }

    private var localBuildNote: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(
                    title: "Local-first account mode",
                    subtitle: "This build is ready to use with email and password right now.",
                    eyebrow: "Identity"
                )

                Text("Apple Sign-In and Google Sign-In stay hidden until their external setup is finished. That keeps this local build focused on the path that already works end to end.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            }
        }
    }

    private var footerNote: some View {
        Text("Email sign-in is the primary local path for now. Special Pro access is still respected internally and bypasses subscription checks when that account signs in.")
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(AppTheme.textMuted)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
    }
}
