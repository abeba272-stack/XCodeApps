import XCTest
@testable import AIContentMachine

final class TemplateEngineCatalogTests: XCTestCase {
    func testDefaultTemplateCatalogIsSeedReadyAndBalanced() {
        let templates = TemplateEngine.makeDefaultTemplates()

        XCTAssertEqual(templates.count, 22)
        XCTAssertEqual(templates.filter { $0.tier == .free }.count, 8)
        XCTAssertEqual(templates.filter(\.isPro).count, 14)
        XCTAssertEqual(Set(templates.map(\.seedKey)).count, templates.count)
        XCTAssertTrue(templates.allSatisfy { !$0.blueprint.isEmpty })
        XCTAssertTrue(templates.allSatisfy { !$0.exampleScriptDirection.isEmpty })
        XCTAssertTrue(templates.allSatisfy { !$0.exampleCaptionDirection.isEmpty })
    }

    func testEveryProTemplateHasAReadyToUseSuggestionAndFreeTemplatesDoNot() {
        let templates = TemplateEngine.makeDefaultTemplates()

        let proTemplates = templates.filter(\.isPro)
        let freeTemplates = templates.filter { $0.tier == .free }

        XCTAssertTrue(proTemplates.allSatisfy(\.hasReadyToUseSuggestion))
        XCTAssertTrue(freeTemplates.allSatisfy { !$0.hasReadyToUseSuggestion })
        XCTAssertTrue(proTemplates.allSatisfy {
            guard let quickStart = $0.quickStartBrief else { return false }
            return !quickStart.topic.isEmpty && !quickStart.audience.isEmpty && quickStart.mode == .fullPackage
        })
    }
}
