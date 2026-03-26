import Foundation

enum GenerationError: LocalizedError {
    case missingInput(String)
    case invalidSettings(String)
    case providerFailure(String)

    var errorDescription: String? {
        switch self {
        case .missingInput(let message): message
        case .invalidSettings(let message): message
        case .providerFailure(let message): message
        }
    }
}

protocol ContentGenerationService: Sendable {
    func generateContent(for request: GenerationRequest) async throws -> GeneratedContent
    func regenerateSection(_ section: ContentSection, for request: GenerationRequest) async throws -> GeneratedContent
}

extension ContentGenerationService {
    func validate(request: GenerationRequest) throws {
        if request.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw GenerationError.missingInput("Add a topic or subject before generating content.")
        }

        if request.audience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw GenerationError.missingInput("Add a target audience before generating content.")
        }
    }
}
