//
//  CityServicing.swift
//  Fluffy
//

protocol CityServicing {
    func fetchCities() async throws -> [City]
}
