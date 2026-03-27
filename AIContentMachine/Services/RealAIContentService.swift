import Foundation

struct RealAIContentService: ContentGenerationService {
    private let engine: AIEngine

    init(endpoint: URL, networkClient: any NetworkClient, logger: any AppLogger) {
        self.engine = AIEngine(
            client: LocalAIClient(endpoint: endpoint, networkClient: networkClient),
            promptBuilder: LocalPromptBuilder(),
            responseParser: LocalResponseParser(),
            baselineGenerator: MockContentGenerationService(),
            logger: logger
        )
    }

    func generateContent(for request: GenerationRequest) async throws -> GeneratedContent {
        try await engine.generateContent(for: request)
    }

    func regenerateSection(_ section: ContentSection, for request: GenerationRequest) async throws -> GeneratedContent {
        try await engine.regenerateSection(section, for: request)
    }
}
