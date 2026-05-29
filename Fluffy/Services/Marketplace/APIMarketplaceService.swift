//
//  APIMarketplaceService.swift
//  Fluffy
//

import Foundation

struct APIMarketplaceService: MarketplaceServicing {
    private let client: APIClient
    private let authenticatedClient: AuthenticatedAPIClient
    private let sessionStore: AuthSessionStoring

    init(
        client: APIClient,
        authenticatedClient: AuthenticatedAPIClient,
        sessionStore: AuthSessionStoring
    ) {
        self.client = client
        self.authenticatedClient = authenticatedClient
        self.sessionStore = sessionStore
    }

    func fetchListings(query: ListingQuery) async throws -> MarketplacePage<Listing> {
        let accessToken = try await authenticatedClient.accessToken()
        var queryItems = [
            URLQueryItem(name: "page", value: "\(query.page)"),
            URLQueryItem(name: "pageSize", value: "\(query.pageSize)")
        ]

        if let category = query.category, category != .all {
            queryItems.append(URLQueryItem(name: "category", value: category.backendValue))
        }

        let search = query.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }

        if let lat = query.latitude {
            queryItems.append(URLQueryItem(name: "latitude", value: "\(lat)"))
        }
        if let lon = query.longitude {
            queryItems.append(URLQueryItem(name: "longitude", value: "\(lon)"))
        }
        if let rad = query.radius {
            queryItems.append(URLQueryItem(name: "radius", value: "\(rad)"))
        }

        let page: BackendPage<BackendListingResponse> = try await client.get(
            "/api/v1/listings",
            queryItems: queryItems,
            accessToken: accessToken
        )
        let favoritesPage: BackendPage<BackendListingResponse>? = try? await client.get(
            "/api/v1/favorites",
            accessToken: accessToken
        )

        let favoriteIDs = favoritesPage?.items.map(\.id) ?? []
        let favorites = Set(favoriteIDs)
        let items = page.items.map { $0.listing(isFavorite: favorites.contains($0.id) || $0.isFavorite) }
        return MarketplacePage(items: items, page: page.page, pageSize: page.pageSize, hasMore: page.hasMore)
    }

    func fetchShelters() async throws -> [Shelter] {
        let page: BackendPage<BackendShelterResponse> = try await client.get(
            "/api/v1/shelters",
            queryItems: [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "pageSize", value: "50")
            ]
        )
        return page.items.map(\.shelter)
    }

    func fetchPetSitters() async throws -> [PetSitter] {
        let page: BackendPage<BackendPetSitterResponse> = try await client.get(
            "/api/v1/pet-sitters",
            queryItems: [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "pageSize", value: "50")
            ]
        )
        return page.items.map(\.petSitter)
    }

    func fetchConversations() async throws -> [Conversation] {
        let accessToken = try await authenticatedClient.accessToken()
        let chats: [BackendChatResponse] = try await client.get("/api/v1/chats", accessToken: accessToken)
        var conversations: [Conversation] = []
        for chat in chats {
            let messagesPage: BackendPage<BackendChatMessageResponse> = try await client.get(
                "/api/v1/chats/\(chat.id)/messages",
                accessToken: accessToken
            )
            let listing = try await fetchListingIfNeeded(chat.listingId, accessToken: accessToken)
            conversations.append(chat.conversation(
                messages: messagesPage.items,
                listing: listing,
                currentUserID: sessionStore.loadSession()?.user.id
            ))
        }
        return conversations
    }

    func fetchUserProfile() async throws -> UserProfile {
        let accessToken = try await authenticatedClient.accessToken()
        let response: BackendProfileResponse = try await client.get("/api/v1/profile/me", accessToken: accessToken)
        return response.profile
    }

    func createListing(from draft: ListingDraft) async throws -> Listing {
        let accessToken = try await authenticatedClient.accessToken()
        let request = ListingCreateRequest(draft: draft)
        let response: BackendListingResponse = try await client.post(
            "/api/v1/listings",
            body: request,
            accessToken: accessToken
        )
        return response.listing()
    }

    func setFavorite(listingID: String, isFavorite: Bool) async throws {
        let accessToken = try await authenticatedClient.accessToken()
        let path = "/api/v1/listings/\(listingID)/favorite"
        if isFavorite {
            let _: FavoriteResponse = try await client.post(path, body: EmptyBody(), accessToken: accessToken)
        } else {
            let _: FavoriteResponse = try await client.delete(path, accessToken: accessToken)
        }
    }

    func createConversation(for listingID: String) async throws -> Conversation {
        let accessToken = try await authenticatedClient.accessToken()
        let request = ChatCreateRequest(
            listingId: listingID,
            initialMessage: String(localized: "chat_new_conversation_message")
        )
        let chat: BackendChatResponse = try await client.post("/api/v1/chats", body: request, accessToken: accessToken)
        let messagesPage: BackendPage<BackendChatMessageResponse> = try await client.get(
            "/api/v1/chats/\(chat.id)/messages",
            accessToken: accessToken
        )
        let listing = try await fetchListingIfNeeded(chat.listingId, accessToken: accessToken)
        return chat.conversation(messages: messagesPage.items, listing: listing, currentUserID: sessionStore.loadSession()?.user.id)
    }

    func sendMessage(_ text: String, in conversationID: String) async throws -> ChatMessage {
        let accessToken = try await authenticatedClient.accessToken()
        let request = ChatMessageCreateRequest(text: text)
        let response: BackendChatMessageResponse = try await client.post(
            "/api/v1/chats/\(conversationID)/messages",
            body: request,
            accessToken: accessToken
        )
        return response.message(currentUserID: sessionStore.loadSession()?.user.id)
    }

    func markRead(conversationID: String) async throws {
        let accessToken = try await authenticatedClient.accessToken()
        let path = "/api/v1/chats/\(conversationID)/read"
        let _: EmptyResponse = try await client.post(path, body: EmptyBody(), accessToken: accessToken)
    }

    func updateUserProfile(_ draft: UserProfileDraft) async throws -> UserProfile {
        let accessToken = try await authenticatedClient.accessToken()
        let request = ProfileUpdateRequest(draft: draft)
        let response: BackendProfileResponse = try await client.patch(
            "/api/v1/profile/me",
            body: request,
            accessToken: accessToken
        )
        return response.profile
    }

    func requestShelterHelp(_ request: ShelterHelpRequest) async throws {
        let accessToken = try await authenticatedClient.accessToken()
        let _: EmptyResponse = try await client.post(
            "/api/v1/shelters/\(request.shelterID)/help",
            body: DirectoryContactRequest(message: request.message),
            accessToken: accessToken
        )
    }

    func contactPetSitter(_ request: PetSitterContactRequest) async throws -> Conversation {
        let accessToken = try await authenticatedClient.accessToken()
        let chat: BackendChatResponse = try await client.post(
            "/api/v1/pet-sitters/\(request.petSitterID)/contact",
            body: DirectoryContactRequest(message: request.message),
            accessToken: accessToken
        )
        let sitter = try await fetchPetSitter(id: request.petSitterID)
        let messagesPage: BackendPage<BackendChatMessageResponse> = try await client.get(
            "/api/v1/chats/\(chat.id)/messages",
            accessToken: accessToken
        )
        return chat.conversation(
            messages: messagesPage.items,
            listing: nil,
            petSitter: sitter,
            currentUserID: sessionStore.loadSession()?.user.id
        )
    }

    func requestProfileVerification(message: String?) async throws -> ProfileVerificationResponse {
        let accessToken = try await authenticatedClient.accessToken()
        let response: BackendVerificationStatusResponse = try await client.post(
            "/api/v1/profile/verification",
            body: VerificationCreateRequest(message: message),
            accessToken: accessToken
        )
        return response.verification
    }

    func fetchProfileVerificationStatus() async throws -> ProfileVerificationResponse {
        let accessToken = try await authenticatedClient.accessToken()
        let response: BackendVerificationStatusResponse = try await client.get(
            "/api/v1/profile/verification/status",
            accessToken: accessToken
        )
        return response.verification
    }

    private func fetchListingIfNeeded(_ id: String?, accessToken: String) async throws -> BackendListingResponse? {
        guard let id else { return nil }
        return try await client.get("/api/v1/listings/\(id)", accessToken: accessToken)
    }

    private func fetchPetSitter(id: String) async throws -> BackendPetSitterResponse? {
        let page: BackendPage<BackendPetSitterResponse> = try await client.get(
            "/api/v1/pet-sitters",
            queryItems: [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "pageSize", value: "100")
            ]
        )
        return page.items.first { $0.id == id }
    }
}

private struct BackendPage<Item: Decodable>: Decodable {
    let items: [Item]
    let page: Int
    let pageSize: Int
    let hasMore: Bool
}

private struct EmptyBody: Encodable {}

private struct EmptyResponse: Decodable {
    let ok: Bool
}

private struct DirectoryContactRequest: Encodable {
    let message: String?
}

private struct FavoriteResponse: Decodable {
    let listingId: String
    let isFavorite: Bool
}

private struct ListingCreateRequest: Encodable {
    let category: String
    let title: String
    let description: String
    let animalType: String
    let petType: String
    let breed: String?
    let age: String?
    let sex: String
    let gender: String
    let city: String
    let location: String
    let isUrgent: Bool
    let pricePerDay: Int?
    let price: Int?
    let reward: Int?
    let tags: [String]
    let photoIds: [String]
    let locationPrecision: String

    init(draft: ListingDraft) {
        let location = draft.normalizedLocation
        self.category = draft.resolvedCategory.backendValue
        self.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.description = draft.submissionDescription
        self.animalType = draft.animalType.rawValue
        self.petType = draft.animalType.rawValue
        self.breed = draft.breed.trimmingCharacters(in: .whitespacesAndNewlines)
        self.age = draft.age.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sex = draft.sex.rawValue
        self.gender = draft.sex.rawValue
        self.city = draft.normalizedCity
        self.location = location
        self.isUrgent = draft.isUrgent || draft.urgencyLevel == .urgent || draft.publicationType == .urgentHelp
        self.pricePerDay = draft.publicationFormat == .commercial ? draft.pricePerDay : nil
        self.price = draft.publicationFormat == .commercial ? draft.pricePerDay : nil
        self.reward = draft.reward
        self.tags = draft.tags
        self.photoIds = draft.photoIds
        self.locationPrecision = "city"
    }
}

private struct ProfileUpdateRequest: Encodable {
    let name: String
    let handle: String?
    let city: String
    let phone: String
    let avatarUrl: String?

    init(draft: UserProfileDraft) {
        self.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHandle = draft.handle.trimmingCharacters(in: .whitespacesAndNewlines)
        self.handle = trimmedHandle.isEmpty ? nil : trimmedHandle
        self.city = draft.city.trimmingCharacters(in: .whitespacesAndNewlines)
        self.phone = draft.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        self.avatarUrl = draft.avatarURL?.absoluteString
    }
}

private struct VerificationCreateRequest: Encodable {
    let message: String?
}

private struct BackendVerificationStatusResponse: Decodable {
    let status: VerificationStatus
    let latestRequestId: String?
    let updatedAt: Date?

    var verification: ProfileVerificationResponse {
        ProfileVerificationResponse(status: status, latestRequestId: latestRequestId, updatedAt: updatedAt)
    }
}

private struct ChatCreateRequest: Encodable {
    let listingId: String?
    let initialMessage: String?
}

private struct ChatMessageCreateRequest: Encodable {
    let text: String
}

private struct BackendProfileResponse: Decodable {
    let email: String
    let name: String?
    let handle: String?
    let city: String?
    let phone: String?
    let avatarUrl: String?
    let avatarURL: String?
    let rating: Double?
    let reviews: Int?
    let listingsCount: Int?
    let dealsCount: Int?
    let daysOnPlatform: Int?

    var profile: UserProfile {
        UserProfile(
            name: clean(name, fallback: email.components(separatedBy: "@").first ?? "Fluffy"),
            handle: clean(handle, fallback: "@fluffy"),
            city: clean(city, fallback: ""),
            email: email,
            phone: clean(phone, fallback: ""),
            avatarURL: URL(string: avatarURL ?? avatarUrl ?? ""),
            rating: rating ?? 0,
            reviews: reviews ?? 0,
            listingsCount: listingsCount ?? 0,
            dealsCount: dealsCount ?? 0,
            daysOnPlatform: daysOnPlatform ?? 0
        )
    }
}

private struct BackendListingResponse: Decodable {
    let id: String
    let category: String
    let title: String
    let description: String
    let petType: String?
    let animalType: String?
    let breed: String?
    let age: String?
    let gender: String?
    let sex: String?
    let city: String?
    let district: String?
    let location: String?
    let isUrgent: Bool
    let price: Int?
    let pricePerDay: Int?
    let tags: [String]
    let photos: [BackendListingPhotoResponse]?
    let imageURL: String?
    let author: BackendListingAuthorResponse?
    let authorName: String?
    let authorAvatarURL: String?
    let date: Date?
    let createdAt: Date?
    let isFavorite: Bool
    let distance: Double?

    func listing(isFavorite favoriteOverride: Bool? = nil) -> Listing {
        Listing(
            id: id,
            category: ListingCategory(backendValue: category),
            title: title,
            animalType: AnimalType(rawValue: animalType ?? petType ?? "") ?? .other,
            breed: clean(breed, fallback: "-"),
            age: clean(age, fallback: "-"),
            sex: PetSex(rawValue: sex ?? gender ?? "") ?? .male,
            location: clean(location, fallback: [city, district].compactMap { $0 }.joined(separator: ", ")),
            imageURL: URL(string: imageURL ?? photos?.first?.url ?? ""),
            description: description,
            authorName: clean(authorName ?? author?.name, fallback: "Fluffy user"),
            authorAvatarURL: URL(string: authorAvatarURL ?? author?.avatarUrl ?? ""),
            date: listingDate(from: date ?? createdAt),
            tags: tags,
            isUrgent: isUrgent,
            pricePerDay: pricePerDay ?? price,
            isFavorite: favoriteOverride ?? isFavorite,
            distance: distance
        )
    }
}

private struct BackendListingPhotoResponse: Decodable {
    let url: String
}

private struct BackendListingAuthorResponse: Decodable {
    let name: String?
    let avatarUrl: String?
}

private struct BackendShelterResponse: Decodable {
    let id: String
    let name: String
    let city: String
    let imageURL: String?
    let imageUrl: String?
    let animals: Int
    let description: String
    let phone: String
    let urgentCount: Int

    var shelter: Shelter {
        Shelter(
            id: id,
            name: name,
            city: city,
            imageURL: URL(string: imageURL ?? imageUrl ?? ""),
            animals: animals,
            description: description,
            phone: phone,
            urgentCount: urgentCount
        )
    }
}

private struct BackendPetSitterResponse: Decodable {
    let id: String
    let name: String
    let avatarURL: String?
    let avatarUrl: String?
    let rating: Double
    let reviews: Int
    let pricePerDay: Int
    let location: String
    let services: [String]
    let bio: String
    let animalTypes: [String]

    var petSitter: PetSitter {
        PetSitter(
            id: id,
            name: name,
            avatarURL: URL(string: avatarURL ?? avatarUrl ?? ""),
            rating: rating,
            reviews: reviews,
            pricePerDay: pricePerDay,
            location: location,
            services: services,
            bio: bio,
            animalTypes: animalTypes.compactMap { AnimalType(rawValue: $0) }
        )
    }
}

private struct BackendChatResponse: Decodable {
    let id: String
    let listingId: String?
    let participantIds: [String]
    let lastMessage: String?
    let unreadCount: Int?
    let createdAt: Date?
    let updatedAt: Date?

    func conversation(
        messages: [BackendChatMessageResponse],
        listing: BackendListingResponse?,
        petSitter: BackendPetSitterResponse? = nil,
        currentUserID: String?
    ) -> Conversation {
        let mappedMessages = messages.map { $0.message(currentUserID: currentUserID) }
        let last = mappedMessages.last?.text ?? lastMessage ?? String(localized: "chat_new_conversation_message")
        return Conversation(
            id: id,
            name: petSitter?.name ?? listing?.authorName ?? listing?.author?.name ?? String(localized: "chat_unknown_user"),
            avatarURL: petSitter?.petSitter.avatarURL ?? URL(string: listing?.authorAvatarURL ?? listing?.author?.avatarUrl ?? ""),
            lastMessage: last,
            time: listingDate(from: updatedAt ?? createdAt),
            unreadCount: unreadCount ?? 0,
            listingTitle: listing?.title ?? petSitter?.name ?? String(localized: "add_listing"),
            messages: mappedMessages
        )
    }
}

private struct BackendChatMessageResponse: Decodable {
    let id: String
    let senderId: String
    let text: String
    let createdAt: Date?

    func message(currentUserID: String?) -> ChatMessage {
        ChatMessage(
            id: id,
            text: text,
            sender: senderId == currentUserID ? .me : .them,
            time: listingDate(from: createdAt)
        )
    }
}

private extension ListingCategory {
    var backendValue: String {
        switch self {
        case .all, .rehome:
            "rehome"
        case .lost:
            "lost"
        case .found:
            "found"
        case .boardingNeeded:
            "boardingNeeded"
        case .boardingOffer:
            "boardingOffer"
        case .petsitting:
            "petsitting"
        case .volunteer:
            "volunteer"
        }
    }

    init(backendValue: String) {
        switch backendValue {
        case "lost", "lostPet":
            self = .lost
        case "found", "foundPet":
            self = .found
        case "boardingNeeded", "temporaryCare":
            self = .boardingNeeded
        case "boardingOffer":
            self = .boardingOffer
        case "petSitting", "petsitting":
            self = .petsitting
        case "volunteer", "otherHelp":
            self = .volunteer
        case "adoption", "rehome", "shelters":
            self = .rehome
        default:
            self = .rehome
        }
    }
}

private func clean(_ value: String?, fallback: String) -> String {
    let cleaned = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return cleaned.isEmpty ? fallback : cleaned
}

private func listingDate(from date: Date?) -> String {
    guard let date else { return String(localized: "chat_now") }
    return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
}
