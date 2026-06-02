//
//  MediaService.swift
//  Fluffy
//

import Foundation

protocol MediaServicing {
    func uploadProfileAvatar(data: Data, fileName: String, mimeType: String) async throws -> URL
    func uploadListingPhoto(data: Data, fileName: String, mimeType: String) async throws -> ListingPhotoUpload
    func uploadChatPhoto(data: Data, chatID: String, fileName: String, mimeType: String) async throws -> URL
}

struct ListingPhotoUpload: Hashable {
    let mediaId: String
    let url: URL
}

struct APIMediaService: MediaServicing {
    private let client: APIClient
    private let authenticatedClient: AuthenticatedAPIClient

    init(client: APIClient, authenticatedClient: AuthenticatedAPIClient) {
        self.client = client
        self.authenticatedClient = authenticatedClient
    }

    func uploadProfileAvatar(data: Data, fileName: String, mimeType: String) async throws -> URL {
        let response = try await uploadMedia(data: data, ownerType: "profile", listingId: nil, fileName: fileName, mimeType: mimeType)
        guard let url = URL(string: response.publicUrl) else {
            throw APIClientError.invalidURL
        }
        return url
    }

    func uploadListingPhoto(data: Data, fileName: String, mimeType: String) async throws -> ListingPhotoUpload {
        let response = try await uploadMedia(data: data, ownerType: "listing", listingId: nil, fileName: fileName, mimeType: mimeType)
        guard let url = URL(string: response.publicUrl) else {
            throw APIClientError.invalidURL
        }
        return ListingPhotoUpload(mediaId: response.mediaId, url: url)
    }

    func uploadChatPhoto(data: Data, chatID: String, fileName: String, mimeType: String) async throws -> URL {
        let response = try await uploadMedia(data: data, ownerType: "chat", listingId: chatID, fileName: fileName, mimeType: mimeType)
        guard let url = URL(string: response.publicUrl) else {
            throw APIClientError.invalidURL
        }
        return url
    }

    private func uploadMedia(data: Data, ownerType: String, listingId: String?, fileName: String, mimeType: String) async throws -> MediaUploadResponse {
        let accessToken = try await authenticatedClient.accessToken()
        let signedUpload: MediaUploadResponse = try await client.post(
            "/api/v1/media/upload-url",
            body: MediaUploadURLRequest(
                ownerType: ownerType,
                listingId: listingId,
                fileName: fileName,
                mimeType: mimeType,
                byteSize: data.count
            ),
            accessToken: accessToken
        )
        try await upload(data: data, mimeType: mimeType, to: signedUpload)
        try await complete(mediaId: signedUpload.mediaId, accessToken: accessToken)
        return signedUpload
    }

    private func upload(data: Data, mimeType: String, to signedUpload: MediaUploadResponse) async throws {
        guard signedUpload.method.uppercased() == "PUT",
              let url = URL(string: signedUpload.uploadUrl)
        else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.upload(for: request, from: data)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIClientError.httpStatus(httpResponse.statusCode, requestID: nil)
        }
    }

    private func complete(mediaId: String, accessToken: String) async throws {
        let _: MediaCompleteResponse = try await client.post(
            "/api/v1/media/complete",
            body: MediaCompleteRequest(mediaId: mediaId),
            accessToken: accessToken
        )
    }
}

struct MockMediaService: MediaServicing {
    func uploadProfileAvatar(data: Data, fileName: String, mimeType: String) async throws -> URL {
        URL(string: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=160&h=160&fit=crop&auto=format")!
    }

    func uploadListingPhoto(data: Data, fileName: String, mimeType: String) async throws -> ListingPhotoUpload {
        ListingPhotoUpload(
            mediaId: UUID().uuidString,
            url: URL(string: "https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?w=600&h=600&fit=crop&auto=format")!
        )
    }

    func uploadChatPhoto(data: Data, chatID: String, fileName: String, mimeType: String) async throws -> URL {
        URL(string: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&h=500&fit=crop&auto=format")!
    }
}

private struct MediaUploadResponse: Decodable {
    let mediaId: String
    let uploadUrl: String
    let publicUrl: String
    let method: String
}

private struct MediaUploadURLRequest: Encodable {
    let ownerType: String
    let listingId: String?
    let fileName: String
    let mimeType: String
    let byteSize: Int
}

private struct MediaCompleteRequest: Encodable {
    let mediaId: String
}

private struct MediaCompleteResponse: Decodable {
    let ok: Bool
}
