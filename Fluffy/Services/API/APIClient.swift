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

    func uploadMultipart<ResponseBody: Decodable>(
        _ path: String,
        fields: [String: String],
        fileFieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data,
        accessToken: String? = nil
    ) async throws -> ResponseBody {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try makeRequest(path: path, method: "POST", accessToken: accessToken)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeMultipartBody(
            boundary: boundary,
            fields: fields,
            fileFieldName: fileFieldName,
            fileName: fileName,
            mimeType: mimeType,
            fileData: fileData
        )
        return try await send(request)
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

    private func makeMultipartBody(
        boundary: String,
        fields: [String: String],
        fileFieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        for (name, value) in fields {
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak)\(lineBreak)")
            body.append("\(value)\(lineBreak)")
        }

        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(fileName)\"\(lineBreak)")
        body.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)")
        body.append(fileData)
        body.append(lineBreak)
        body.append("--\(boundary)--\(lineBreak)")
        return body
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

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
