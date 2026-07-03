//
//  APIClient.swift
//  Fluffy
//

import Foundation

struct APIClient {
    static let requestIDHeader = "X-Request-ID"

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
        request.setValue(UUID().uuidString, forHTTPHeaderField: Self.requestIDHeader)
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
            let responseRequestID = httpResponse.value(forHTTPHeaderField: Self.requestIDHeader)
            if let errorEnvelope = try? decoder.decode(APIErrorEnvelope.self, from: data) {
                throw APIClientError.api(
                    code: errorEnvelope.error.code,
                    message: errorEnvelope.error.message,
                    requestID: errorEnvelope.error.requestId ?? responseRequestID
                )
            }

            throw APIClientError.httpStatus(httpResponse.statusCode, requestID: responseRequestID)
        }
    }
}

enum APIClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int, requestID: String?)
    case api(code: String, message: String, requestID: String?)

    var errorDescription: String? {
        let message: String
        switch self {
        case .invalidURL:
            message = String(localized: "api_error_invalid_url")
        case .invalidResponse:
            message = String(localized: "api_error_invalid_response")
        case let .httpStatus(status, _):
            message = status == 429
                ? String(localized: "api_error_rate_limited")
                : String(format: String(localized: "api_error_http_status"), status)
        case let .api(code, apiMessage, _):
            message = Self.userFacingAPIMessage(code: code, fallback: apiMessage)
        }
        guard let requestID else { return message }
        return String(format: String(localized: "api_error_request_id_suffix"), message, requestID)
    }

    var requestID: String? {
        switch self {
        case .invalidURL, .invalidResponse:
            nil
        case let .httpStatus(_, requestID), let .api(_, _, requestID):
            requestID
        }
    }

    var apiCode: String? {
        switch self {
        case let .api(code, _, _):
            code
        default:
            nil
        }
    }

    private static func userFacingAPIMessage(code: String, fallback: String) -> String {
        switch code {
        case "rate_limited":
            return String(localized: "api_error_rate_limited")
        case "verification_required":
            return String(localized: "api_error_verification_required")
        default:
            return fallback
        }
    }
}

private struct APIErrorEnvelope: Decodable {
    let error: APIErrorBody
}

private struct APIErrorBody: Decodable {
    let code: String
    let message: String
    let requestId: String?
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
