import Foundation

struct RealAIContentService: ContentGenerationService {
    let apiKey: String
    let endpoint: URL
    let model: String
    private let fallback = MockContentGenerationService()

    func generateContent(for request: GenerationRequest) async throws -> GeneratedContent {
        try validate(request: request)

        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GenerationError.invalidSettings("Enter an API key in Settings before enabling the real AI provider.")
        }

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload = ProviderPayload(
            model: model,
            instructions: systemInstructions(language: request.language),
            request: request
        )

        urlRequest.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw GenerationError.providerFailure("The AI provider returned an unexpected response. Switch back to Offline Mock mode or verify your endpoint.")
        }

        do {
            let decoded = try JSONDecoder().decode(ProviderResponse.self, from: data)
            var content = decoded.content
            content.score = ContentScoreCalculator.score(for: content, request: request)
            return content
        } catch {
            _ = try await fallback.generateContent(for: request)
            throw GenerationError.providerFailure("The AI response could not be decoded into the expected content schema. Offline mock content is available immediately in Settings.")
        }
    }

    func regenerateSection(_ section: ContentSection, for request: GenerationRequest) async throws -> GeneratedContent {
        try await generateContent(for: request)
    }
}

private extension RealAIContentService {
    struct ProviderPayload: Encodable {
        var model: String
        var instructions: String
        var request: ProviderRequest

        init(model: String, instructions: String, request: GenerationRequest) {
            self.model = model
            self.instructions = instructions
            self.request = ProviderRequest(request: request)
        }
    }

    struct ProviderRequest: Encodable {
        var topic: String
        var platform: String
        var category: String
        var audience: String
        var tone: String
        var language: String
        var goal: String
        var style: String
        var durationSeconds: Int
        var mode: String
        var templateName: String?
        var templateDescription: String?
        var templateRules: [String]

        init(request: GenerationRequest) {
            topic = request.topic
            platform = request.platform.rawValue
            category = request.category
            audience = request.audience
            tone = request.tone.rawValue
            language = request.language.rawValue
            goal = request.goal.rawValue
            style = request.style.rawValue
            durationSeconds = request.durationSeconds
            mode = request.mode.rawValue
            templateName = request.templateName
            templateDescription = request.templateDescription
            templateRules = request.templateRules
        }
    }

    struct ProviderResponse: Decodable {
        var content: GeneratedContent
    }

    func systemInstructions(language: ContentLanguage) -> String {
        if language == .german {
            return "Antworte nur mit JSON fuer das GeneratedContent-Schema. Keine Markdown-Ausgabe. Schreibe hochwertigen Creator-Content auf Deutsch."
        }
        return "Return JSON only for the GeneratedContent schema. No markdown. Write high-quality creator content in English."
    }
}
