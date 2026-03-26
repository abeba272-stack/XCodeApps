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
}
