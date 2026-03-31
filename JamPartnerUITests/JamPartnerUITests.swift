import XCTest

final class JamPartnerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["JamPartner"].exists, "Title should be visible")
    }
}
