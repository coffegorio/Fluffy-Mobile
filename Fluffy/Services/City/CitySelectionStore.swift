//
//  CitySelectionStore.swift
//  Fluffy
//

import Foundation

protocol CitySelectionStoring {
    func loadSelectedCitySlug() -> String?
    func saveSelectedCitySlug(_ slug: String)
}

struct UserDefaultsCitySelectionStore: CitySelectionStoring {
    private let key = "fluffy.selectedCitySlug"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSelectedCitySlug() -> String? {
        defaults.string(forKey: key)
    }

    func saveSelectedCitySlug(_ slug: String) {
        defaults.set(slug, forKey: key)
    }
}
