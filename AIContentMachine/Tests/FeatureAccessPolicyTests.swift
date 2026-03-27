import XCTest
@testable import AIContentMachine

final class FeatureAccessPolicyTests: XCTestCase {
    func testFreePolicyMatchesProductModel() {
        XCTAssertEqual(FeatureAccessPolicy.freeGenerationLimitPerMonth, 8)
        XCTAssertTrue(FeatureAccessPolicy.freeGenerationModes.contains(.singleIdea))
        XCTAssertTrue(FeatureAccessPolicy.freeGenerationModes.contains(.fullPackage))
        XCTAssertFalse(FeatureAccessPolicy.freeGenerationModes.contains(.batchIdeas))
        XCTAssertEqual(FeatureAccessPolicy.freeProviderModes, [.mock])
        XCTAssertEqual(FeatureAccessPolicy.proProviderModes, [.customEndpoint])
    }

    func testUsageWindowStartNormalizesToMonthBoundary() {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 27
        components.hour = 16
        components.minute = 42

        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)!
        let windowStart = FeatureAccessPolicy.usageWindowStart(for: date, calendar: calendar)

        let normalized = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: windowStart)
        XCTAssertEqual(normalized.year, 2026)
        XCTAssertEqual(normalized.month, 3)
        XCTAssertEqual(normalized.day, 1)
        XCTAssertEqual(normalized.hour, 0)
        XCTAssertEqual(normalized.minute, 0)
    }
}
