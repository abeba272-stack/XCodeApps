import Foundation

protocol AIClient: Sendable {
    func send(prompt: String) async throws -> String
}

protocol PromptBuilder: Sendable {
    func makePrompt(from request: GenerationRequest) -> String
}

protocol ResponseParser: Sendable {
    func parse(raw: String, request: GenerationRequest, baseline: GeneratedContent) throws -> GeneratedContent
}

struct AIEngine: ContentGenerationService {
    private let client: any AIClient
    private let promptBuilder: any PromptBuilder
    private let responseParser: any ResponseParser
    private let baselineGenerator: any ContentGenerationService
    private let logger: any AppLogger

    init(
        client: any AIClient,
        promptBuilder: any PromptBuilder,
        responseParser: any ResponseParser,
        baselineGenerator: any ContentGenerationService,
        logger: any AppLogger
    ) {
        self.client = client
        self.promptBuilder = promptBuilder
        self.responseParser = responseParser
        self.baselineGenerator = baselineGenerator
        self.logger = logger
    }

    func generateContent(for request: GenerationRequest) async throws -> GeneratedContent {
        try validate(request: request)

        let baseline = try await baselineGenerator.generateContent(for: request)
        let prompt = promptBuilder.makePrompt(from: request)
        let raw: String

        do {
            raw = try await client.send(prompt: prompt)
        } catch {
            guard shouldFallbackToOffline(for: error) else {
                throw error
            }

            logger.warn("Custom endpoint failed, falling back to offline mode: \(error.localizedDescription)", category: "AIEngine")
            return makeFallbackContent(from: baseline, for: request)
        }

        var parsed = try responseParser.parse(raw: raw, request: request, baseline: baseline)
        parsed.origin = .provider
        return parsed
    }

    func regenerateSection(_ section: ContentSection, for request: GenerationRequest) async throws -> GeneratedContent {
        try await generateContent(for: request)
    }
}

private extension AIEngine {
    func shouldFallbackToOffline(for error: Error) -> Bool {
        switch error {
        case is NetworkFailure:
            return true
        case let generationError as GenerationError:
            if case .providerFailure = generationError {
                return true
            }
            return false
        case is URLError:
            return true
        default:
            return false
        }
    }

    func makeFallbackContent(from baseline: GeneratedContent, for request: GenerationRequest) -> GeneratedContent {
        var fallbackContent = baseline
        let notice = request.language == .german
            ? "Hinweis: Der lokale AI-Server konnte nicht genutzt werden. Dieser Entwurf wurde im Offline-Modus generiert."
            : "Note: The local AI server could not be used. This draft was generated in offline mode."

        fallbackContent.notes = baseline.notes.isEmpty ? notice : "\(notice)\n\(baseline.notes)"
        fallbackContent.origin = .providerFallback
        return fallbackContent
    }
}

struct LocalAIClient: AIClient {
    private let endpoint: URL
    private let networkClient: any NetworkClient

    init(endpoint: URL, networkClient: any NetworkClient) {
        self.endpoint = endpoint
        self.networkClient = networkClient
    }

    func send(prompt: String) async throws -> String {
        let payload = LocalServerPayload(prompt: prompt)
        let data = try JSONEncoder().encode(payload)
        let request = NetworkRequest(
            url: endpoint,
            method: "POST",
            headers: ["Content-Type": "application/json"],
            body: data
        )

        let responseData = try await networkClient.send(request, retryPolicy: .standard)
        guard let rawText = String(data: responseData, encoding: .utf8) else {
            throw NetworkFailure.decoding("The local AI response could not be decoded as UTF-8.")
        }

        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw NetworkFailure.emptyResponse
        }

        return text
    }

    private struct LocalServerPayload: Encodable {
        let prompt: String
    }
}

struct RemoteAIClient: AIClient {
    func send(prompt: String) async throws -> String {
        throw GenerationError.invalidSettings("Remote AI providers are not configured yet.")
    }
}

struct LocalPromptBuilder: PromptBuilder {
    func makePrompt(from request: GenerationRequest) -> String {
        """
        \(request.userContext.isEmpty ? "" : "User Context:\n\(request.userContext)\n\n")
        Topic: \(request.topic)
        Platform: \(request.platform.rawValue)
        Category: \(request.category)
        Audience: \(request.audience)
        Tone: \(request.tone.rawValue)
        Language: \(request.language.rawValue)
        Goal: \(request.goal.rawValue)
        Style: \(request.style.rawValue)
        Duration: \(request.durationSeconds) seconds
        Mode: \(request.mode.rawValue)
        Template: \(request.templateName ?? "None")

        Generate content for this request.
        """
    }
}

struct LocalResponseParser: ResponseParser {
    func parse(raw: String, request: GenerationRequest, baseline: GeneratedContent) throws -> GeneratedContent {
        let responseText = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !responseText.isEmpty else {
            throw GenerationError.providerFailure("Local server returned an empty response.")
        }

        let lines = responseText
            .split(separator: "\n")
            .map { line in
                line
                    .replacingOccurrences(of: #"^\s*[-•*\d\.\)]\s*"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }

        var content = baseline

        switch request.mode {
        case .singleIdea:
            content.overview = responseText
            if let firstLine = lines.first {
                content.hook = firstLine
            }
            content.notes = responseText

        case .batchIdeas:
            if !lines.isEmpty {
                content.batchIdeas = Array(lines.prefix(10))
            } else {
                content.batchIdeas = [responseText]
            }
            content.overview = responseText
            content.notes = responseText

        case .fullPackage:
            content.overview = responseText
            content.script = responseText
            content.voiceover = responseText
            content.notes = responseText

            if let firstLine = lines.first {
                content.hook = firstLine
            }

            if lines.count > 1 {
                content.alternateHooks = Array(lines.dropFirst().prefix(3))
            }
        }

        content.score = ContentScoreCalculator.score(for: content, request: request)
        return content
    }
}

@MainActor
struct DefaultContentGenerationServiceFactory: ContentGenerationServiceFactory {
    private let networkClient: any NetworkClient
    private let logger: any AppLogger

    init(networkClient: any NetworkClient, logger: any AppLogger) {
        self.networkClient = networkClient
        self.logger = logger
    }

    func makeService(for settings: AppSettings) throws -> any ContentGenerationService {
        switch settings.providerMode {
        case .mock:
            return MockContentGenerationService()
        case .customEndpoint:
            guard let endpoint = settings.localServerURL else {
                throw GenerationError.invalidSettings("Add a valid local AI server endpoint in Settings.")
            }

            return AIEngine(
                client: LocalAIClient(endpoint: endpoint, networkClient: networkClient),
                promptBuilder: LocalPromptBuilder(),
                responseParser: LocalResponseParser(),
                baselineGenerator: MockContentGenerationService(),
                logger: logger
            )
        }
    }
}
