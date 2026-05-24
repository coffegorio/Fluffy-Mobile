//
//  RussianScreenshotUITests.swift
//  FluffyUITests
//

import XCTest

final class RussianScreenshotUITests: XCTestCase {
    private var outputDirectory: URL!

    override func setUpWithError() throws {
        continueAfterFailure = false

        let path = ProcessInfo.processInfo.environment["FLUFFY_SCREENSHOT_DIR"]
            ?? "/Users/coffegorio/Development/Fluffy/iOS/Fluffy-SUI/Screenshots/Russian-2026-05-24"
        outputDirectory = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )
    }

    func testCaptureRussianAppFlow() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(ru)",
            "-AppleLocale", "ru_RU",
            "-ResetAuthSession",
            "-UITestAuthEmail", "tester@example.com",
            "-UITestAuthCode", "123456",
            "-MockMarketplaceLatencyMS", "0"
        ]
        app.launch()

        capture("01-welcome")

        tapButton("Вперед", in: app)
        capture("02-auth-email")

        tapButton("Получить код", in: app)
        capture("03-auth-code")

        tapButton("Войти", in: app)
        XCTAssertTrue(app.staticTexts["Fluffy"].waitForExistence(timeout: 10))
        capture("04-home")

        tapTab("Поиск", in: app)
        capture("05-search")

        tapButton("Добавить объявление", in: app)
        capture("06-add-listing")
        tapButton("Отмена", in: app)

        tapTab("Чаты", in: app)
        capture("07-chats")

        app.staticTexts["Анна М."].tap()
        capture("08-conversation")
        tapBack(in: app)

        tapTab("Избранное", in: app)
        capture("09-favorites")

        tapTab("Профиль", in: app)
        capture("10-profile")
    }

    func testCaptureRussianSheltersOnly() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(ru)",
            "-AppleLocale", "ru_RU",
            "-ResetAuthSession",
            "-UITestAuthEmail", "tester@example.com",
            "-UITestAuthCode", "123456",
            "-MockMarketplaceLatencyMS", "0",
            "-UITestInitialRoute", "shelters"
        ]
        app.launch()

        tapButton("Вперед", in: app)
        tapButton("Получить код", in: app)
        tapButton("Войти", in: app)
        XCTAssertTrue(app.staticTexts["Приюты"].waitForExistence(timeout: 10))
        capture("11-shelters")
    }

    func testCaptureRussianPetSittingOnly() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(ru)",
            "-AppleLocale", "ru_RU",
            "-ResetAuthSession",
            "-UITestAuthEmail", "tester@example.com",
            "-UITestAuthCode", "123456",
            "-MockMarketplaceLatencyMS", "0",
            "-UITestInitialRoute", "petSitting"
        ]
        app.launch()

        tapButton("Вперед", in: app)
        tapButton("Получить код", in: app)
        tapButton("Войти", in: app)
        XCTAssertTrue(app.staticTexts["Pet-sitting"].waitForExistence(timeout: 10))
        capture("12-pet-sitting")
    }

    private func capture(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let url = outputDirectory.appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: url)
    }

    private func tapButton(_ label: String, in app: XCUIApplication) {
        let button = app.buttons[label].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing button: \(label)")
        button.tap()
        sleep(1)
    }

    private func tapTab(_ label: String, in app: XCUIApplication) {
        let tab = app.tabBars.buttons[label].firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Missing tab: \(label)")
        tab.tap()
        sleep(1)
    }

    private func tapIdentifier(_ identifier: String, in app: XCUIApplication) {
        let button = app.buttons[identifier].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing button identifier: \(identifier)")
        button.tap()
        sleep(1)
    }

    private func tapBack(in app: XCUIApplication) {
        let localizedBack = app.buttons["Назад"].firstMatch
        if localizedBack.waitForExistence(timeout: 2) {
            localizedBack.tap()
            sleep(1)
            return
        }

        let commonBack = app.buttons["common_back"].firstMatch
        XCTAssertTrue(commonBack.waitForExistence(timeout: 5), "Missing back button")
        commonBack.tap()
        sleep(1)
    }

    private func tapButton(containing text: String, in app: XCUIApplication) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let button = app.buttons.matching(predicate).firstMatch
        if button.waitForExistence(timeout: 5) {
            button.tap()
            sleep(1)
            return
        }

        let combinedButton = app.buttons.containing(.staticText, identifier: text).firstMatch
        XCTAssertTrue(combinedButton.waitForExistence(timeout: 5), "Missing button containing: \(text)")
        combinedButton.tap()
        sleep(1)
    }
}
