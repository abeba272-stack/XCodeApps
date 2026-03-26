import XCTest
@testable import AIContentMachine

final class ContentScoreCalculatorTests: XCTestCase {
    func testScoreStaysWithinBounds() {
        let request = GenerationRequest(
            topic: "content systems",
            platform: .youtubeShorts,
            category: "Business",
            audience: "Founders",
            tone: .educational,
            language: .english,
            goal: .authority,
            style: .tutorial,
            durationSeconds: 45,
            mode: .fullPackage
        )

        let content = GeneratedContent(
            title: "The fastest content system for authority",
            topic: "content systems",
            contentAngle: "Tight authority angle",
            audienceSummary: "Founders who want clarity",
            overview: "A practical operating system for short-form creation.",
            hook: "If your content feels random, your system is broken.",
            alternateHooks: ["You do not need more ideas.", "Most content chaos is structural.", "Stop guessing your posting workflow."],
            script: "1. Hook\n2. Diagnose the system gap\n3. Show the fix\n4. CTA",
            voiceover: "If your content feels random, your system is broken.",
            caption: "Short-form authority comes from repeatable systems, not random inspiration.",
            hashtags: ["#contentsystems", "#authoritycontent", "#shorts"],
            cta: "Save this and rebuild your workflow before your next post.",
            shotList: ["Hook close-up", "Workflow overlay", "Checklist screen", "Direct CTA"],
            notes: "Local mock sample",
            performanceRationale: "The structure improves credibility and platform fit.",
            bestPostingTime: "8:00 AM",
            emotionalTrigger: "Tension between chaos and control.",
            templateUsed: nil,
            batchIdeas: [],
            thumbnailSuggestions: ["Fix your system"],
            postingChecklist: ["Lead with hook"],
            postingTip: "Use a simple cover.",
            status: .draft,
            score: 0
        )

        let score = ContentScoreCalculator.score(for: content, request: request)
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score, 100)
        XCTAssertGreaterThan(score, 70)
    }

    func testWeakProjectScoresLowerThanStrongProject() {
        let weak = ContentProject(
            title: "weak",
            topic: "topic",
            category: "General",
            platform: .x,
            audience: "Everyone",
            tone: .direct,
            language: .english,
            goal: .views,
            style: .shortPunchyHook,
            durationSeconds: 15,
            generationMode: .singleIdea,
            contentAngle: "",
            audienceSummary: "",
            overview: "",
            hook: "Short hook",
            alternateHooks: [],
            script: "",
            voiceover: "",
            caption: "tiny",
            hashtags: [],
            cta: "Follow",
            shotList: [],
            notes: "",
            performanceRationale: "",
            bestPostingTime: "",
            emotionalTrigger: "",
            templateUsed: nil,
            batchIdeas: [],
            thumbnailSuggestions: [],
            postingChecklist: [],
            postingTip: "",
            contentScore: 0
        )

        let strong = ContentProject(
            title: "The system behind content consistency",
            topic: "content consistency",
            category: "Business",
            platform: .instagramReels,
            audience: "Founders",
            tone: .educational,
            language: .english,
            goal: .authority,
            style: .tutorial,
            durationSeconds: 35,
            generationMode: .fullPackage,
            contentAngle: "System over motivation",
            audienceSummary: "Founders who want repeatable output",
            overview: "A sharper way to build weekly content.",
            hook: "If your content quality swings, your workflow is the problem.",
            alternateHooks: ["Your system is leaking attention."],
            script: "1. Hook\n2. Problem\n3. Fix\n4. CTA",
            voiceover: "If your content quality swings, your workflow is the problem.",
            caption: "Build a system strong enough to survive low motivation days.",
            hashtags: ["#contentstrategy", "#reelsgrowth", "#foundermarketing"],
            cta: "Save this and audit your content workflow today.",
            shotList: ["Hook shot", "Whiteboard", "Checklist", "CTA close-up"],
            notes: "",
            performanceRationale: "Clear hook, credibility, and platform fit.",
            bestPostingTime: "7:00 PM",
            emotionalTrigger: "From chaos to control.",
            templateUsed: nil,
            batchIdeas: [],
            thumbnailSuggestions: ["Fix your workflow"],
            postingChecklist: ["Hook early"],
            postingTip: "Keep captions clean.",
            contentScore: 0
        )

        XCTAssertLessThan(ContentScoreCalculator.score(for: weak), ContentScoreCalculator.score(for: strong))
    }
}
