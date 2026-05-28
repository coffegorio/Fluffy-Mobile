//
//  APIClient.swift
//  Fluffy
//

import Foundation

struct APIClient {
    let configuration: APIConfiguration
    var urlSession: URLSession = .shared

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func get<ResponseBody: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = [],
        accessToken: String? = nil
    ) async throws -> ResponseBody {
        let request = try makeRequest(path: path, method: "GET", queryItems: queryItems, accessToken: accessToken)
        return try await send(request)
    }

    func post<RequestBody: Encodable, ResponseBody: Decodable>(
        _ path: String,
        body: RequestBody,
        accessToken: String? = nil
    ) async throws -> ResponseBody {
        var request = try makeRequest(path: path, method: "POST", accessToken: accessToken)
        request.httpBody = try encoder.encode(body)
        return try await send(request)
    }

    func patch<RequestBody: Encodable, ResponseBody: Decodable>(
        _ path: String,
        body: RequestBody,
        accessToken: String? = nil
    ) async throws -> ResponseBody {
        var request = try makeRequest(path: path, method: "PATCH", accessToken: accessToken)
        request.httpBody = try encoder.encode(body)
        return try await send(request)
    }

    func delete<ResponseBody: Decodable>(
        _ path: String,
        accessToken: String? = nil
    ) async throws -> ResponseBody {
        let request = try makeRequest(path: path, method: "DELETE", accessToken: accessToken)
        return try await send(request)
    }

    func post<RequestBody: Encodable>(
        _ path: String,
        body: RequestBody,
        accessToken: String? = nil
    ) async throws {
        var request = try makeRequest(path: path, method: "POST", accessToken: accessToken)
        request.httpBody = try encoder.encode(body)
        _ = try await sendEmpty(request)
    }

    private func makeRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        accessToken: String?
    ) throws -> URLRequest {
        guard let baseURL = URL(string: path, relativeTo: configuration.baseURL),
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        else {
            throw APIClientError.invalidURL
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func send<ResponseBody: Decodable>(_ request: URLRequest) async throws -> ResponseBody {
        let (data, response) = try await urlSession.data(for: request)
        try validate(data: data, response: response)
        return try decoder.decode(ResponseBody.self, from: data)
    }

    private func sendEmpty(_ request: URLRequest) async throws {
        let (data, response) = try await urlSession.data(for: request)
        try validate(data: data, response: response)
    }

    private func validate(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let errorEnvelope = try? decoder.decode(APIErrorEnvelope.self, from: data) {
                throw APIClientError.api(code: errorEnvelope.error.code, message: errorEnvelope.error.message)
            }

            throw APIClientError.httpStatus(httpResponse.statusCode)
        }
    }
}

enum APIClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case api(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid API URL."
        case .invalidResponse:
            "Invalid API response."
        case let .httpStatus(status):
            "Request failed with status \(status)."
        case let .api(_, message):
            message
        }
    }
}

private struct APIErrorEnvelope: Decodable {
    let error: APIErrorBody
}

private struct APIErrorBody: Decodable {
    let code: String
    let message: String
}
