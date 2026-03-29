import XCTest
@testable import AIContentMachine

final class MockContentGenerationServiceTests: XCTestCase {
    func testFullPackageGenerationProducesStructuredOutput() async throws {
        let service = MockContentGenerationService()
        let request = GenerationRequest(
            topic: "Why creators burn out after posting consistently",
            platform: .tiktok,
            category: "Self Improvement",
            audience: "Solo creators",
            tone: .serious,
            language: .english,
            goal: .engagement,
            style: .deepExplanation,
            durationSeconds: 35,
            mode: .fullPackage,
            template: TemplateEngine.makeDefaultTemplates().first
        )

        let content = try await service.generateContent(for: request)

        XCTAssertFalse(content.title.isEmpty)
        XCTAssertFalse(content.hook.isEmpty)
        XCTAssertFalse(content.script.isEmpty)
        XCTAssertFalse(content.caption.isEmpty)
        XCTAssertEqual(content.alternateHooks.count, 3)
        XCTAssertGreaterThanOrEqual(content.hashtags.count, 4)
        XCTAssertGreaterThanOrEqual(content.shotList.count, 4)
        XCTAssertGreaterThan(content.score, 0)

        let project = ContentProject.from(request: request, generated: content)
        let videoPrompt = CopyExportService.videoPromptText(for: project)
        XCTAssertFalse(videoPrompt.isEmpty)

        [
            "[HOOK_VISUAL]",
            "[SCENE]",
            "[CAMERA]",
            "[MOTION]",
            "[STYLE]",
            "[LIGHTING]",
            "[SOUND]",
            "[DURATION]"
        ]
        .forEach { section in
            XCTAssertTrue(videoPrompt.contains(section), "Expected video prompt to contain \(section)")
        }

        XCTAssertTrue(videoPrompt.contains("3-5 seconds"))
        XCTAssertTrue(videoPrompt.localizedCaseInsensitiveContains("creators") || videoPrompt.localizedCaseInsensitiveContains("burn out"))
    }

    func testBatchGenerationCreatesTenIdeas() async throws {
        let service = MockContentGenerationService()
        let request = GenerationRequest(
            topic: "anime storytelling",
            platform: .instagramReels,
            category: "Anime",
            audience: "Fans who love breakdowns",
            tone: .emotional,
            language: .english,
            goal: .views,
            style: .top3List,
            durationSeconds: 25,
            mode: .batchIdeas
        )

        let content = try await service.generateContent(for: request)

        XCTAssertEqual(content.batchIdeas.count, 10)
        XCTAssertTrue(content.title.localizedCaseInsensitiveContains("10"))
    }

    func testUnknownCategoryStillProducesEnglishOutput() async throws {
        let service = MockContentGenerationService()
        let request = GenerationRequest(
            topic: "calm creator systems",
            platform: .tiktok,
            category: "Obscure Category That Does Not Match",
            audience: "Solo creators",
            tone: .direct,
            language: .english,
            goal: .views,
            style: .educational,
            durationSeconds: 30,
            mode: .fullPackage
        )

        let content = try await service.generateContent(for: request)

        XCTAssertFalse(content.hook.isEmpty)
        XCTAssertFalse(content.caption.isEmpty)
        XCTAssertFalse(content.cta.isEmpty)
    }

    func testUnknownCategoryStillProducesGermanOutput() async throws {
        let service = MockContentGenerationService()
        let request = GenerationRequest(
            topic: "ruhige creator systeme",
            platform: .instagramReels,
            category: "Komplett Unbekannte Kategorie",
            audience: "deutsche Creator",
            tone: .direct,
            language: .german,
            goal: .engagement,
            style: .educational,
            durationSeconds: 30,
            mode: .fullPackage
        )

        let content = try await service.generateContent(for: request)

        XCTAssertFalse(content.hook.isEmpty)
        XCTAssertFalse(content.caption.isEmpty)
        XCTAssertFalse(content.cta.isEmpty)
    }

    func testGenerationUsesFallbackTagsForNonAlphanumericInputs() async throws {
        let service = MockContentGenerationService()
        let request = GenerationRequest(
            topic: "!!! ???",
            platform: .tiktok,
            category: "???",
            audience: "Creators",
            tone: .direct,
            language: .english,
            goal: .views,
            style: .educational,
            durationSeconds: 25,
            mode: .fullPackage
        )

        let content = try await service.generateContent(for: request)

        XCTAssertFalse(content.hashtags.isEmpty)
        XCTAssertTrue(content.hashtags.allSatisfy { $0.count > 1 })
        XCTAssertFalse(content.hashtags.contains("#"))
        XCTAssertTrue(content.hashtags.contains("#content"))
        XCTAssertTrue(content.hashtags.contains("#generalcreator"))
    }
}

final class AIEngineTests: XCTestCase {
    func testGenerateContentReturnsParsedProviderOutputOnSuccess() async throws {
        let engine = AIEngine(
            client: StubAIClient(result: .success("provider raw response")),
            promptBuilder: StubPromptBuilder(),
            responseParser: StubResponseParser(result: .success(makeGeneratedContent(notes: "Parsed from provider"))),
            baselineGenerator: StubBaselineGenerator(result: .success(makeGeneratedContent(notes: "Baseline"))),
            logger: StubLogger()
        )

        let content = try await engine.generateContent(for: makeRequest())

        XCTAssertEqual(content.origin, .live)
        XCTAssertEqual(content.notes, "Parsed from provider")
    }

    func testGenerateContentFallsBackForReachabilityFailures() async throws {
        let engine = AIEngine(
            client: StubAIClient(result: .failure(NetworkFailure.transport("connection refused"))),
            promptBuilder: StubPromptBuilder(),
            responseParser: StubResponseParser(result: .success(makeGeneratedContent(notes: "Parsed"))),
            baselineGenerator: StubBaselineGenerator(result: .success(makeGeneratedContent(notes: "Baseline note"))),
            logger: StubLogger()
        )

        let content = try await engine.generateContent(for: makeRequest(language: .english))

        XCTAssertEqual(content.origin, .fallback)
        XCTAssertTrue(content.notes.contains("mock generator"))
        XCTAssertTrue(content.notes.contains("Baseline note"))
    }

    func testGenerateContentSurfacesParserFailures() async {
        let engine = AIEngine(
            client: StubAIClient(result: .success("provider raw response")),
            promptBuilder: StubPromptBuilder(),
            responseParser: StubResponseParser(result: .failure(StubFailure.parser)),
            baselineGenerator: StubBaselineGenerator(result: .success(makeGeneratedContent(notes: "Baseline"))),
            logger: StubLogger()
        )

        await XCTAssertThrowsErrorAsync(try await engine.generateContent(for: makeRequest())) { error in
            XCTAssertEqual(error as? StubFailure, .parser)
        }
    }

    func testGenerateContentSurfacesConfigurationFailures() async {
        let engine = AIEngine(
            client: StubAIClient(result: .failure(GenerationError.invalidSettings("Missing configuration"))),
            promptBuilder: StubPromptBuilder(),
            responseParser: StubResponseParser(result: .success(makeGeneratedContent(notes: "Parsed"))),
            baselineGenerator: StubBaselineGenerator(result: .success(makeGeneratedContent(notes: "Baseline"))),
            logger: StubLogger()
        )

        await XCTAssertThrowsErrorAsync(try await engine.generateContent(for: makeRequest())) { error in
            guard case GenerationError.invalidSettings(let message) = error else {
                return XCTFail("Expected invalidSettings error, got \(error)")
            }
            XCTAssertEqual(message, "Missing configuration")
        }
    }

    func testGenerateContentSurfacesProviderFailuresWithoutFallback() async {
        let engine = AIEngine(
            client: StubAIClient(result: .failure(GenerationError.providerFailure("Provider returned HTTP 500"))),
            promptBuilder: StubPromptBuilder(),
            responseParser: StubResponseParser(result: .success(makeGeneratedContent(notes: "Parsed"))),
            baselineGenerator: StubBaselineGenerator(result: .success(makeGeneratedContent(notes: "Baseline"))),
            logger: StubLogger()
        )

        await XCTAssertThrowsErrorAsync(try await engine.generateContent(for: makeRequest())) { error in
            guard case GenerationError.providerFailure(let message) = error else {
                return XCTFail("Expected providerFailure error, got \(error)")
            }
            XCTAssertEqual(message, "Provider returned HTTP 500")
        }
    }
}

private extension AIEngineTests {
    enum StubFailure: Error, Equatable {
        case parser
    }

    struct StubAIClient: AIClient, @unchecked Sendable {
        let result: Result<String, Error>

        func send(prompt: String) async throws -> String {
            try result.get()
        }
    }

    struct StubPromptBuilder: PromptBuilder {
        func makePrompt(from request: GenerationRequest) -> String {
            "prompt::\(request.topic)"
        }
    }

    struct StubResponseParser: ResponseParser, @unchecked Sendable {
        let result: Result<GeneratedContent, Error>

        func parse(raw: String, request: GenerationRequest, baseline: GeneratedContent) throws -> GeneratedContent {
            try result.get()
        }
    }

    struct StubBaselineGenerator: ContentGenerationService, @unchecked Sendable {
        let result: Result<GeneratedContent, Error>

        func generateContent(for request: GenerationRequest) async throws -> GeneratedContent {
            try result.get()
        }

        func regenerateSection(_ section: ContentSection, for request: GenerationRequest) async throws -> GeneratedContent {
            try result.get()
        }
    }

    struct StubLogger: AppLogger {
        func debug(_ message: String, category: String) {}
        func info(_ message: String, category: String) {}
        func warn(_ message: String, category: String) {}
        func error(_ message: String, category: String) {}
    }

    func makeRequest(language: ContentLanguage = .english) -> GenerationRequest {
        GenerationRequest(
            topic: "content systems",
            platform: .tiktok,
            category: "Business",
            audience: "Founders",
            tone: .direct,
            language: language,
            goal: .authority,
            style: .educational,
            durationSeconds: 30,
            mode: .fullPackage
        )
    }

    func makeGeneratedContent(notes: String) -> GeneratedContent {
        GeneratedContent(
            title: "Title",
            topic: "content systems",
            contentAngle: "Angle",
            audienceSummary: "Audience summary",
            overview: "Overview",
            hook: "Hook",
            alternateHooks: ["Alt 1", "Alt 2", "Alt 3"],
            script: "Script",
            voiceover: "Voiceover",
            caption: "Caption",
            hashtags: ["#acm"],
            cta: "CTA",
            shotList: ["Shot 1"],
            notes: notes,
            performanceRationale: "Rationale",
            bestPostingTime: "8:00 AM",
            emotionalTrigger: "Trigger",
            templateUsed: nil,
            batchIdeas: [],
            thumbnailSuggestions: [],
            postingChecklist: [],
            postingTip: "",
            status: .draft,
            score: 80
        )
    }

    func XCTAssertThrowsErrorAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        _ errorHandler: (Error) -> Void
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error to be thrown")
        } catch {
            errorHandler(error)
        }
    }
}
