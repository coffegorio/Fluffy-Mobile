//
//  APIConfiguration.swift
//  Fluffy
//

import Foundation

struct APIConfiguration {
    let baseURL: URL

    static var live: APIConfiguration {
        if let launchValue = ProcessInfo.processInfo.value(after: "-APIBaseURL"),
           let url = URL(string: launchValue) {
            return APIConfiguration(baseURL: url)
        }

        if let environmentValue = ProcessInfo.processInfo.environment["FLUFFY_API_BASE_URL"],
           let url = URL(string: environmentValue) {
            return APIConfiguration(baseURL: url)
        }

        #if DEBUG
        return APIConfiguration(baseURL: URL(string: "http://127.0.0.1:8080")!)
        #else
        return APIConfiguration(baseURL: URL(string: "https://api.fluffy-infra.ru")!)
        #endif
    }
}

private extension ProcessInfo {
    func value(after key: String) -> String? {
        guard let index = arguments.firstIndex(of: key),
              arguments.indices.contains(index + 1)
        else {
            return nil
        }

        return arguments[index + 1]
    }
}
