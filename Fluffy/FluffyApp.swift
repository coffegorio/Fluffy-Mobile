//
//  FluffyApp.swift
//  Fluffy
//
//  Created by Egor Matveev on 23.04.2026.
//

import SwiftUI
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        NotificationCenter.default.post(
            name: .fluffyAPNsDeviceTokenDidUpdate,
            object: nil,
            userInfo: ["token": token]
        )
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationCenter.default.post(
            name: .fluffyAPNsDeviceTokenRegistrationDidFail,
            object: nil,
            userInfo: ["error": error]
        )
    }
}

@main
struct FluffyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

extension Notification.Name {
    static let fluffyAPNsDeviceTokenDidUpdate = Notification.Name("fluffyAPNsDeviceTokenDidUpdate")
    static let fluffyAPNsDeviceTokenRegistrationDidFail = Notification.Name("fluffyAPNsDeviceTokenRegistrationDidFail")
}
