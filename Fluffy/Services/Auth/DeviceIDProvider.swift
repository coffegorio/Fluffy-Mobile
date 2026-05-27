//
//  DeviceIDProvider.swift
//  Fluffy
//

import Foundation

protocol DeviceIDProviding {
    var deviceID: String { get }
}

struct UserDefaultsDeviceIDProvider: DeviceIDProviding {
    private let key = "fluffy.device-id"

    var deviceID: String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: key) {
            return existing
        }

        let value = UUID().uuidString
        defaults.set(value, forKey: key)
        return value
    }
}
