import AuthenticationServices
import Foundation

enum NetworkFailure: Error, LocalizedError, Equatable {
    case invalidURL(String)
    case transport(String)
    case timedOut
    case invalidResponse
    case unacceptableStatusCode(Int)
    case emptyResponse
    case decoding(String)

    var userMessage: String {
        switch self {
        case .invalidURL:
            return "The local AI server address is invalid."
        case .transport:
            return "The local AI server could not be reached."
        case .timedOut:
            return "The local AI server took too long to respond."
        case .invalidResponse:
            return "The local AI server returned an invalid response."
        case .unacceptableStatusCode:
            return "The local AI server returned an unexpected status."
        case .emptyResponse:
            return "The local AI server returned an empty response."
        case .decoding:
            return "The response from the local AI server could not be processed."
        }
    }

    var errorDescription: String? {
        userMessage
    }
}

enum AppError: LocalizedError, Equatable {
    case validation(String)
    case network(NetworkFailure)
    case persistence(String)
    case export(String)
    case settings(String)
    case ai(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .validation(let message),
             .persistence(let message),
             .export(let message),
             .settings(let message),
             .ai(let message),
             .unknown(let message):
            return message
        case .network(let failure):
            return failure.userMessage
        }
    }
}

extension AppError {
    static func from(_ error: Error, fallback: String) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        if let networkFailure = error as? NetworkFailure {
            return .network(networkFailure)
        }

        if let generationError = error as? GenerationError {
            switch generationError {
            case .missingInput(let message):
                return .validation(message)
            case .invalidSettings(let message):
                return .settings(message)
            case .providerFailure(let message):
                return .ai(message)
            }
        }

        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                return .validation("Apple Sign-In was cancelled.")
            case .failed:
                return .validation("Apple Sign-In is not available in this simulator session. Sign into an Apple ID in the Simulator Settings or use email sign-in.")
            case .invalidResponse:
                return .validation("Apple Sign-In returned an invalid response. Try again or use email sign-in.")
            case .notHandled:
                return .validation("Apple Sign-In could not be completed right now. Try again or use email sign-in.")
            case .unknown:
                return .validation("Apple Sign-In is currently unavailable. Use email sign-in or check the Simulator Apple ID settings.")
            case .matchedExcludedCredential:
                return .validation("This Apple account cannot be used for sign-in here. Try another method.")
            case .credentialImport:
                return .validation("Apple credentials could not be imported. Try again or use email sign-in.")
            case .credentialExport:
                return .validation("Apple credentials could not be exported. Try again or use email sign-in.")
            @unknown default:
                return .validation("Apple Sign-In is currently unavailable. Use email sign-in or try again later.")
            }
        }

        return .unknown(error.localizedDescription.isEmpty ? fallback : error.localizedDescription)
    }
}
