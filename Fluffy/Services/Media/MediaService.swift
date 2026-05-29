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
        let accessToken = try await authenticatedClient.accessToken()
        let response: MediaUploadResponse = try await client.uploadMultipart(
            "/api/v1/media/upload",
            fields: ["ownerType": "profile"],
            fileFieldName: "file",
            fileName: fileName,
            mimeType: mimeType,
            fileData: data,
            accessToken: accessToken
        )
        guard let url = URL(string: response.publicUrl) else {
            throw APIClientError.invalidURL
        }
        return url
    }

    func uploadListingPhoto(data: Data, fileName: String, mimeType: String) async throws -> ListingPhotoUpload {
        let accessToken = try await authenticatedClient.accessToken()
        let response: MediaUploadResponse = try await client.uploadMultipart(
            "/api/v1/media/upload",
            fields: ["ownerType": "listing"],
            fileFieldName: "file",
            fileName: fileName,
            mimeType: mimeType,
            fileData: data,
            accessToken: accessToken
        )
        guard let url = URL(string: response.publicUrl) else {
            throw APIClientError.invalidURL
        }
        return ListingPhotoUpload(mediaId: response.mediaId, url: url)
    }

    func uploadChatPhoto(data: Data, chatID: String, fileName: String, mimeType: String) async throws -> URL {
        let accessToken = try await authenticatedClient.accessToken()
        let response: MediaUploadResponse = try await client.uploadMultipart(
            "/api/v1/media/upload",
            fields: ["ownerType": "chat", "listingId": chatID],
            fileFieldName: "file",
            fileName: fileName,
            mimeType: mimeType,
            fileData: data,
            accessToken: accessToken
        )
        guard let url = URL(string: response.publicUrl) else {
            throw APIClientError.invalidURL
        }
        return url
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
