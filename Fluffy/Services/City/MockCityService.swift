//
//  MockCityService.swift
//  Fluffy
//

struct MockCityService: CityServicing {
    func fetchCities() async throws -> [City] {
        CityCatalog.fallback
    }
}
