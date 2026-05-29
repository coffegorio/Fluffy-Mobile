//
//  MainViewModel.swift
//  Fluffy
//

import Foundation
import Observation
import SwiftUI

enum MainTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case explore
    case chats
    case favorites
    case profile

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .home: "tab_home"
        case .explore: "tab_explore"
        case .chats: "tab_chats"
        case .favorites: "tab_favorites"
        case .profile: "tab_profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .explore: "square.grid.2x2.fill"
        case .chats: "message.fill"
        case .favorites: "heart.fill"
        case .profile: "person.fill"
        }
    }
}

enum MarketplaceRoute: Hashable {
    case listingDetail(String)
    case conversation(String)
    case shelters
    case petSitting
    case map
}

enum MarketplaceSheet: Identifiable, Hashable {
    case addListing
    case status(title: String, message: String)
    case profileAction(ProfileMenuAction)

    var id: String {
        switch self {
        case .addListing: "addListing"
        case let .status(title, message): "status-\(title)-\(message)"
        case let .profileAction(action): "profileAction-\(action.rawValue)"
        }
    }
}

enum ProfileMenuAction: String, Hashable {
    case listings
    case notifications
    case security
    case help
    case about
}

protocol MainCoordinating: AnyObject {
    func updateSession(_ session: AuthSession)
    func signOut()
}

@Observable
@MainActor
final class MainViewModel {
    var selectedTab: MainTab = .home
    var path: [MarketplaceRoute] = []
    var activeSheet: MarketplaceSheet?
    var listings: [Listing] = []
    var shelters: [Shelter] = []
    var petSitters: [PetSitter] = []
    var conversations: [Conversation] = []
    var profile: UserProfile?
    var profileVerification: ProfileVerificationResponse?
    var mapMarkers: [MapMarker] = []
    var selectedMapFilters: Set<MapMarkerKind> = Set(MapMarkerKind.allCases)
    var favoriteListingIDs: Set<String> = []
    var searchText = ""
    var selectedCategory: ListingCategory = .all
    var isLoading = false
    var isPerformingAction = false
    var errorMessage: String?
    var hasMoreListings = false

    private var session: AuthSession?
    private weak var coordinator: MainCoordinating?
    private let marketplaceService: MarketplaceServicing
    private let mapService: MapServicing
    private let mediaService: MediaServicing
    private let webSocketService = WebSocketService()

    init(
        session: AuthSession?,
        coordinator: MainCoordinating?,
        marketplaceService: MarketplaceServicing,
        mapService: MapServicing,
        mediaService: MediaServicing
    ) {
        self.session = session
        self.coordinator = coordinator
        self.marketplaceService = marketplaceService
        self.mapService = mapService
        self.mediaService = mediaService

        #if DEBUG
        if let rawTab = ProcessInfo.processInfo.value(after: "-UITestInitialTab"),
           let tab = MainTab(rawValue: rawTab) {
            selectedTab = tab
        }

        if let rawRoute = ProcessInfo.processInfo.value(after: "-UITestInitialRoute") {
            if let listingID = rawRoute.removingPrefix("listingDetail:") {
                path = [.listingDetail(listingID)]
            } else {
                switch rawRoute {
                case "shelters":
                    path = [.shelters]
                case "petSitting":
                    path = [.petSitting]
                case "map":
                    path = [.map]
                default:
                    break
                }
            }
        }

        if ProcessInfo.processInfo.arguments.contains("-UITestPreloadMarketplaceData") {
            listings = MockMarketplaceData.listings
            shelters = MockMarketplaceData.shelters
            petSitters = MockMarketplaceData.petSitters
            conversations = MockMarketplaceData.conversations
            profile = MockMarketplaceData.profile
            mapMarkers = []
        }
        #endif

        if let token = session?.accessToken {
            webSocketService.delegate = self
            webSocketService.connect(token: token)
        }
    }

    var urgentListings: [Listing] {
        Array(listings.filter(\.isUrgent).prefix(4))
    }

    var recentListings: [Listing] {
        Array(listings.filter { !$0.isUrgent }.prefix(4))
    }

    var filteredListings: [Listing] {
        listings.filter { listing in
            let matchesCategory = selectedCategory == .all || listing.category == selectedCategory
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesSearch = query.isEmpty
                || listing.title.lowercased().contains(query)
                || listing.breed.lowercased().contains(query)
                || listing.location.lowercased().contains(query)

            return matchesCategory && matchesSearch
        }
    }

    var favoriteListings: [Listing] {
        listings.filter { favoriteListingIDs.contains($0.id) }
    }

    var totalUnreadCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    var myListings: [Listing] {
        Array(listings.prefix(2))
    }

    var isVerificationRequired: Bool {
        session?.requiresProfileCompletion == true
    }

    func load(force: Bool = false) async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-UITestPreloadMarketplaceData"), !force {
            isLoading = false
            errorMessage = nil
            return
        }
        #endif

        guard !isLoading || force else { return }

        isLoading = true
        errorMessage = nil

        do {
            async let listingsPage = marketplaceService.fetchListings(query: .firstPage)
            async let shelters = marketplaceService.fetchShelters()
            async let petSitters = marketplaceService.fetchPetSitters()
            async let conversations = marketplaceService.fetchConversations()
            async let profile = marketplaceService.fetchUserProfile()
            async let profileVerification = marketplaceService.fetchProfileVerificationStatus()
            async let mapMarkers = mapService.fetchMarkers(in: .lipetsk, filters: selectedMapFilters)

            let page = try await listingsPage
            self.listings = page.items
            favoriteListingIDs = Set(page.items.filter(\.isFavorite).map(\.id))
            hasMoreListings = page.hasMore
            self.shelters = (try? await shelters) ?? []
            self.petSitters = (try? await petSitters) ?? []
            self.conversations = (try? await conversations) ?? []
            self.profile = try? await profile
            self.profileVerification = try? await profileVerification
            self.mapMarkers = (try? await mapMarkers) ?? []
            isLoading = false

        } catch {
            listings = []
            favoriteListingIDs = []
            hasMoreListings = false
            shelters = []
            petSitters = []
            conversations = []
            mapMarkers = []
            isLoading = false
            errorMessage = nil
        }
    }

    func refresh() async {
        await load(force: true)
    }

    func isFavorite(_ listing: Listing) -> Bool {
        favoriteListingIDs.contains(listing.id)
    }

    func toggleFavorite(_ listing: Listing) {
        let wasFavorite = favoriteListingIDs.contains(listing.id)
        if favoriteListingIDs.contains(listing.id) {
            favoriteListingIDs.remove(listing.id)
        } else {
            favoriteListingIDs.insert(listing.id)
        }

        Task {
            do {
                try await marketplaceService.setFavorite(listingID: listing.id, isFavorite: !wasFavorite)
            } catch {
                if wasFavorite {
                    favoriteListingIDs.insert(listing.id)
                } else {
                    favoriteListingIDs.remove(listing.id)
                }
                errorMessage = String(localized: "marketplace_action_error")
            }
        }
    }

    func showExplore() {
        selectedTab = .explore
    }

    func showListing(_ listing: Listing) {
        path.append(.listingDetail(listing.id))
    }

    func showShelters() {
        path.append(.shelters)
    }

    func showPetSitting() {
        path.append(.petSitting)
    }

    func showMap() {
        path.append(.map)
    }

    func loadMapMarkers(in viewport: MapViewport? = nil) async {
        let targetViewport = viewport ?? .lipetsk

        do {
            mapMarkers = try await mapService.fetchMarkers(in: targetViewport, filters: selectedMapFilters)
        } catch {
            errorMessage = String(localized: "marketplace_load_error")
        }
    }

    func toggleMapFilter(_ filter: MapMarkerKind) {
        if selectedMapFilters.contains(filter) {
            selectedMapFilters.remove(filter)
        } else {
            selectedMapFilters.insert(filter)
        }

        Task {
            await loadMapMarkers()
        }
    }

    func showMapMarker(_ marker: MapMarker) {
        switch marker.target {
        case let .listing(id):
            path.append(.listingDetail(id))
        case .shelters:
            path.append(.shelters)
        case .petSitting:
            path.append(.petSitting)
        }
    }

    func showConversation(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index].unreadCount = 0
        }
        path.append(.conversation(conversation.id))
    }

    func startChat(for listing: Listing) {
        if let conversation = conversations.first(where: { $0.listingTitle == listing.title }) {
            showConversation(conversation)
        } else {
            Task {
                await performAction {
                    let conversation = try await marketplaceService.createConversation(for: listing.id)
                    conversations.insert(conversation, at: 0)
                    selectedTab = .chats
                    path.append(.conversation(conversation.id))
                }
            }
        }
    }

    func listing(withID id: String) -> Listing? {
        listings.first { $0.id == id }
    }

    func conversation(withID id: String) -> Conversation? {
        conversations.first { $0.id == id }
    }

    func sendMessage(_ text: String, in conversationID: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = conversations.firstIndex(where: { $0.id == conversationID })
        else { return }

        let now = String(localized: "chat_now")
        let pendingID = "pending-\(UUID().uuidString)"
        let outgoing = ChatMessage(
            id: pendingID,
            text: trimmed,
            sender: .me,
            time: now
        )

        conversations[index].messages.append(outgoing)
        conversations[index].lastMessage = trimmed
        conversations[index].time = now
        conversations[index].unreadCount = 0

        Task {
            do {
                let sent = try await marketplaceService.sendMessage(trimmed, in: conversationID)
                if let currentIndex = conversations.firstIndex(where: { $0.id == conversationID }),
                   let messageIndex = conversations[currentIndex].messages.firstIndex(where: { $0.id == pendingID }) {
                    conversations[currentIndex].messages[messageIndex] = sent
                }
            } catch {
                errorMessage = String(localized: "marketplace_action_error")
            }
        }
    }

    func sendPhotoMessage(data: Data, in conversationID: String) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }

        let now = String(localized: "chat_now")
        let pendingID = "pending-\(UUID().uuidString)"
        let outgoingPlaceholder = ChatMessage(
            id: pendingID,
            text: "[photo]",
            sender: .me,
            time: now
        )

        conversations[index].messages.append(outgoingPlaceholder)
        conversations[index].lastMessage = String(localized: "chat_photo_last_message", defaultValue: "📸 Фото")
        conversations[index].time = now
        conversations[index].unreadCount = 0

        Task {
            do {
                let uuidString = UUID().uuidString
                let url = try await mediaService.uploadChatPhoto(
                    data: data,
                    chatID: conversationID,
                    fileName: "\(uuidString).jpg",
                    mimeType: "image/jpeg"
                )

                let sent = try await marketplaceService.sendMessage(url.absoluteString, in: conversationID)

                if let currentIndex = conversations.firstIndex(where: { $0.id == conversationID }),
                   let messageIndex = conversations[currentIndex].messages.firstIndex(where: { $0.id == pendingID }) {
                    conversations[currentIndex].messages[messageIndex] = sent
                    conversations[currentIndex].lastMessage = String(localized: "chat_photo_last_message", defaultValue: "📸 Фото")
                }
            } catch {
                if let currentIndex = conversations.firstIndex(where: { $0.id == conversationID }) {
                    conversations[currentIndex].messages.removeAll(where: { $0.id == pendingID })
                }
                errorMessage = String(localized: "marketplace_action_error")
            }
        }
    }

    func showAddListing() {
        activeSheet = .addListing
    }

    func createListing(from draft: ListingDraft) async {
        guard draft.isValid else { return }

        await performAction {
            let listing = try await marketplaceService.createListing(from: draft)
            favoriteListingIDs.remove(listing.id)
            activeSheet = .status(title: "listing_created_title", message: "listing_created_message")
        }
    }

    func requestHelp(for shelter: Shelter) {
        Task {
            await performAction {
                try await marketplaceService.requestShelterHelp(
                    ShelterHelpRequest(
                        shelterID: shelter.id,
                        message: String(localized: "shelter_help_default_message")
                    )
                )
                activeSheet = .status(title: "shelter_help_sent_title", message: "shelter_help_sent_message")
            }
        }
    }

    func contactPetSitter(_ sitter: PetSitter) {
        Task {
            await performAction {
                let conversation = try await marketplaceService.contactPetSitter(
                    PetSitterContactRequest(
                        petSitterID: sitter.id,
                        message: String(localized: "petsitter_contact_default_message")
                    )
                )
                if conversations.contains(where: { $0.id == conversation.id }) == false {
                    conversations.insert(conversation, at: 0)
                }
                selectedTab = .chats
                path.append(.conversation(conversation.id))
            }
        }
    }

    func showProfileAction(_ action: ProfileMenuAction) {
        activeSheet = .profileAction(action)
    }

    func requestProfileVerification(message: String? = nil) async {
        await performAction {
            profileVerification = try await marketplaceService.requestProfileVerification(message: message)
        }
    }

    func showCallPlaceholder() {
        activeSheet = .status(title: "call_unavailable_title", message: "call_unavailable_message")
    }

    func signOut() {
        webSocketService.disconnect()
        coordinator?.signOut()
    }

    deinit {
        let service = webSocketService
        Task { @MainActor in
            service.disconnect()
        }
    }

    private func performAction(_ action: () async throws -> Void) async {
        guard !isPerformingAction else { return }

        isPerformingAction = true
        errorMessage = nil

        do {
            try await action()
            isPerformingAction = false
        } catch {
            isPerformingAction = false
            errorMessage = String(localized: "marketplace_action_error")
        }
    }
}

#if DEBUG
private extension ProcessInfo {
    func value(after key: String) -> String? {
        guard let index = arguments.firstIndex(of: key) else { return nil }
        let valueIndex = arguments.index(after: index)
        guard arguments.indices.contains(valueIndex) else { return nil }
        return arguments[valueIndex]
    }
}

private extension String {
    func removingPrefix(_ prefix: String) -> String? {
        guard hasPrefix(prefix) else { return nil }
        return String(dropFirst(prefix.count))
    }
}
#endif

extension MainViewModel: WebSocketServiceDelegate {
    func webSocketService(_ service: WebSocketService, didReceiveMessage message: WebSocketChatMessage) {
        let sender: ChatMessage.Sender = message.senderId == session?.user.id ? .me : .them
        
        guard let index = conversations.firstIndex(where: { $0.id == message.chatId }) else {
            Task {
                await refreshConversations()
            }
            return
        }
        
        if conversations[index].messages.contains(where: { $0.id == message.id }) {
            return
        }
        
        conversations[index].messages.removeAll(where: { $0.id.hasPrefix("pending-") && $0.text == message.text })
        
        let timeString = DateFormatter.localizedString(from: message.createdAt ?? Date(), dateStyle: .medium, timeStyle: .short)
        let chatMessage = ChatMessage(
            id: message.id,
            text: message.text,
            sender: sender,
            time: timeString
        )
        
        conversations[index].messages.append(chatMessage)
        
        let isPhoto = message.text.hasPrefix("http") && (message.text.contains("/chats/") || message.text.contains("/media/"))
        let displayLastMessage = isPhoto ? String(localized: "chat_photo_last_message", defaultValue: "📸 Фото") : message.text
        
        conversations[index].lastMessage = displayLastMessage
        conversations[index].time = timeString
        
        let isCurrentlyViewing = path.contains(.conversation(message.chatId))
        if !isCurrentlyViewing && sender == .them {
            conversations[index].unreadCount += 1
        } else if isCurrentlyViewing {
            Task {
                try? await marketplaceService.markRead(conversationID: message.chatId)
            }
        }
        
        let conversation = conversations.remove(at: index)
        conversations.insert(conversation, at: 0)
    }

    func refreshConversations() async {
        do {
            let fetched = try await marketplaceService.fetchConversations()
            self.conversations = fetched
        } catch {
            print("Failed to refresh conversations: \(error)")
        }
    }
}
