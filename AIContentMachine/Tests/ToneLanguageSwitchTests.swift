import XCTest
@testable import AIContentMachine

final class ToneLanguageSwitchTests: XCTestCase {
    func testLanguageSwitchChangesOutputLanguage() async throws {
        let service = MockContentGenerationService()
        let germanRequest = GenerationRequest(
            topic: "Disziplin im Alltag",
            platform: .tiktok,
            category: "Self Improvement",
            audience: "deutsche Creator",
            tone: .serious,
            language: .german,
            goal: .followers,
            style: .educational,
            durationSeconds: 30,
            mode: .fullPackage
        )

        let englishRequest = GenerationRequest(
            topic: "daily discipline",
            platform: .tiktok,
            category: "Self Improvement",
            audience: "English-speaking creators",
            tone: .serious,
            language: .english,
            goal: .followers,
            style: .educational,
            durationSeconds: 30,
            mode: .fullPackage
        )

        let german = try await service.generateContent(for: germanRequest)
        let english = try await service.generateContent(for: englishRequest)

        XCTAssertNotEqual(german.hook, english.hook)
        XCTAssertTrue(german.overview.localizedCaseInsensitiveContains("sachlich") || german.hook.localizedCaseInsensitiveContains("Wenn"))
        XCTAssertTrue(english.overview.localizedCaseInsensitiveContains("measured") || english.hook.localizedCaseInsensitiveContains("If"))
    }

    func testToneShiftChangesOverviewDescriptor() async throws {
        let service = MockContentGenerationService()
        let serious = GenerationRequest(
            topic: "creator burnout",
            platform: .instagramReels,
            category: "Mental Health",
            audience: "Ambitious creators",
            tone: .serious,
            language: .english,
            goal: .engagement,
            style: .storytime,
            durationSeconds: 30,
            mode: .fullPackage
        )

        let funny = GenerationRequest(
            topic: "creator burnout",
            platform: .instagramReels,
            category: "Mental Health",
            audience: "Ambitious creators",
            tone: .funny,
            language: .english,
            goal: .engagement,
            style: .storytime,
            durationSeconds: 30,
            mode: .fullPackage
        )

        let seriousContent = try await service.generateContent(for: serious)
        let funnyContent = try await service.generateContent(for: funny)

        XCTAssertNotEqual(seriousContent.overview, funnyContent.overview)
        XCTAssertTrue(seriousContent.overview.localizedCaseInsensitiveContains("measured"))
        XCTAssertTrue(funnyContent.overview.localizedCaseInsensitiveContains("smart and light"))
    }
}
