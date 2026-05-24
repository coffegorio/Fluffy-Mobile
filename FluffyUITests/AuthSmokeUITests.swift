//
//  AuthSmokeUITests.swift
//  FluffyUITests
//

import XCTest

final class AuthSmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testEmailCodeAuthFlowOpensMarketplace() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-ResetAuthSession",
            "-UITestAuthEmail", "tester@example.com",
            "-UITestAuthCode", "123456",
            "-MockMarketplaceLatencyMS", "0"
        ]
        app.launch()

        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.staticTexts["Sign in to Fluffy"].waitForExistence(timeout: 5))

        let emailField = app.textFields["auth_email_field"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 3))
        XCTAssertEqual(emailField.value as? String, "tester@example.com")

        let sendCodeButton = app.buttons["Send code"]
        XCTAssertTrue(sendCodeButton.waitUntilEnabled(timeout: 3))
        sendCodeButton.tap()

        let codeField = app.textFields["auth_code_field"]
        XCTAssertTrue(codeField.waitForExistence(timeout: 5))
        XCTAssertEqual(codeField.value as? String, "123456")

        let signInButton = app.buttons["Sign in"]
        XCTAssertTrue(signInButton.waitUntilEnabled(timeout: 3))
        signInButton.tap()

        XCTAssertTrue(app.staticTexts["Fluffy"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Home"].exists)
    }
}

private extension XCUIElement {
    func waitUntilEnabled(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND enabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
