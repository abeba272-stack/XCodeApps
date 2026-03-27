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
}
