//
//  MarketplaceSmokeUITests.swift
//  FluffyUITests
//

import XCTest

final class MarketplaceSmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testTabsRenderPrimaryScreens() throws {
        let app = launchIntoMarketplace()

        XCTAssertTrue(app.staticTexts["Fluffy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Urgently looking for a home"].waitForExistence(timeout: 5))

        app.buttons["Search"].tap()
        XCTAssertTrue(app.staticTexts["Listings"].waitForExistence(timeout: 3))

        app.buttons["Chats"].tap()
        XCTAssertTrue(app.staticTexts["Анна М."].waitForExistence(timeout: 8))

        app.buttons["Favorites"].tap()
        XCTAssertTrue(app.staticTexts["Favorites"].waitForExistence(timeout: 8))

        app.buttons["Profile"].tap()
        XCTAssertTrue(app.staticTexts["Profile"].waitForExistence(timeout: 8))
    }

    func testListingDetailOpensFromExplore() throws {
        let app = launchIntoMarketplace()

        app.buttons["Search"].tap()
        XCTAssertTrue(app.staticTexts["Бадди ищет дом"].waitForExistence(timeout: 5))
        app.staticTexts["Бадди ищет дом"].tap()

        XCTAssertTrue(app.staticTexts["Description"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Write"].exists)
        XCTAssertTrue(app.buttons["Back"].exists)
    }

    func testFavoritesCanRemoveItem() throws {
        let app = launchIntoMarketplace()

        app.buttons["Favorites"].tap()
        XCTAssertTrue(app.staticTexts["Favorites"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Бадди ищет дом"].waitForExistence(timeout: 5))

        app.buttons["Remove from favorites"].firstMatch.tap()
        XCTAssertFalse(app.staticTexts["Бадди ищет дом"].waitForExistence(timeout: 2))
    }

    func testChatConversationOpens() throws {
        let app = launchIntoMarketplace()

        app.buttons["Chats"].tap()
        XCTAssertTrue(app.staticTexts["Анна М."].waitForExistence(timeout: 5))
        app.staticTexts["Анна М."].tap()

        XCTAssertTrue(app.staticTexts["Бадди ищет дом"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["chat_message_field"].waitForExistence(timeout: 3))
    }
}

private extension MarketplaceSmokeUITests {
    func launchIntoMarketplace() -> XCUIApplication {
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
        XCTAssertEqual(app.textFields["auth_email_field"].value as? String, "tester@example.com")

        XCTAssertTrue(app.buttons["Send code"].waitUntilEnabled(timeout: 5))
        app.buttons["Send code"].tap()
        XCTAssertTrue(app.textFields["auth_code_field"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["auth_code_field"].value as? String, "123456")

        XCTAssertTrue(app.buttons["Sign in"].waitUntilEnabled(timeout: 5))
        app.buttons["Sign in"].tap()
        XCTAssertTrue(app.staticTexts["Fluffy"].waitForExistence(timeout: 10))

        return app
    }
}

private extension XCUIElement {
    func waitUntilEnabled(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND enabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
