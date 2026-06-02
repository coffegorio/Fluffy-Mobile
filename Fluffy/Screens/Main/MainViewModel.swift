//
//  MainViewModel.swift
//  Fluffy
//

import Foundation
import Observation
import OSLog
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
    case myListings
    case myReports
}

enum MarketplaceSheet: Identifiable, Hashable {
    case addListing
    case editListing(Listing)
    case reportListing(Listing)
    case reportTarget(ReportTarget)
    case verificationRequest
    case status(title: String, message: String)
    case profileAction(ProfileMenuAction)

    var id: String {
        switch self {
        case .addListing: "addListing"
        case let .editListing(listing): "editListing-\(listing.id)"
        case let .reportListing(listing): "reportListing-\(listing.id)"
        case let .reportTarget(target): "reportTarget-\(target.sheetID)"
        case .verificationRequest: "verificationRequest"
        case let .status(title, message): "status-\(title)-\(message)"
        case let .profileAction(action): "profileAction-\(action.rawValue)"
        }
    }
}

enum ProfileMenuAction: String, Hashable {
    case listings
    case reports
    case notifications
    case security
    case help
    case about
}

protocol MainCoordinating: AnyObject {
    func updateSession(_ session: AuthSession)
    func signOut(allDevices: Bool)
}

@Observable
@MainActor
final class MainViewModel {
    private static let logger = Logger(subsystem: "ru.fluffy.app", category: "main-view-model")

    var selectedTab: MainTab = .home
    var path: [MarketplaceRoute] = []
    var activeSheet: MarketplaceSheet?
    var listings: [Listing] = []
    var shelters: [Shelter] = []
    var petSitters: [PetSitter] = []
    var conversations: [Conversation] = []
    var myListings: [Listing] = []
    var myReports: [ReportResponse] = []
    var profile: UserProfile?
    var profileVerification: ProfileVerificationResponse?
    var notificationPreferences = NotificationPreferences()
    var blockedUsers: [BlockedUser] = []
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
    private let accessTokenProvider: AccessTokenProviding
    private let webSocketService = WebSocketService()
    private var loadedConversationMessageIDs: Set<String> = []

    init(
        session: AuthSession?,
        coordinator: MainCoordinating?,
        marketplaceService: MarketplaceServicing,
        mapService: MapServicing,
        mediaService: MediaServicing,
        accessTokenProvider: AccessTokenProviding
    ) {
        self.session = session
        self.coordinator = coordinator
        self.marketplaceService = marketplaceService
        self.mapService = mapService
        self.mediaService = mediaService
        self.accessTokenProvider = accessTokenProvider

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
                case "myListings":
                    path = [.myListings]
                case "myReports":
                    path = [.myReports]
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
            myListings = MockMarketplaceData.myListings
            myReports = MockMarketplaceData.reports
            notificationPreferences = MockMarketplaceData.notificationPreferences
            profile = MockMarketplaceData.profile
            mapMarkers = []
        }
        #endif

        if session != nil {
            webSocketService.delegate = self
            webSocketService.connect { [accessTokenProvider] in
                try await accessTokenProvider.accessToken()
            }
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

    var isVerificationRequired: Bool {
        session?.requiresProfileCompletion == true
    }

    var currentVerificationStatus: VerificationStatus {
        profileVerification?.status ?? profile?.verificationStatus ?? session?.verificationStatus ?? .notStarted
    }

    var shouldShowVerificationNotice: Bool {
        currentVerificationStatus != .approved
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
            async let myListings = marketplaceService.fetchMyListings()
            async let myReports = marketplaceService.fetchMyReports()
            async let profile = marketplaceService.fetchUserProfile()
            async let profileVerification = marketplaceService.fetchProfileVerificationStatus()
            async let notificationPreferences = marketplaceService.fetchNotificationPreferences()
            async let mapMarkers = mapService.fetchMarkers(in: .lipetsk, filters: selectedMapFilters)

            let page = try await listingsPage
            self.listings = page.items
            favoriteListingIDs = Set(page.items.filter(\.isFavorite).map(\.id))
            hasMoreListings = page.hasMore
            self.shelters = (try? await shelters) ?? []
            self.petSitters = (try? await petSitters) ?? []
            self.conversations = mergeConversationSummaries((try? await conversations) ?? [])
            self.myListings = (try? await myListings) ?? []
            self.myReports = (try? await myReports) ?? []
            self.profile = try? await profile
            self.profileVerification = try? await profileVerification
            self.notificationPreferences = (try? await notificationPreferences) ?? NotificationPreferences()
            self.mapMarkers = (try? await mapMarkers) ?? []
            isLoading = false

        } catch {
            listings = []
            favoriteListingIDs = []
            hasMoreListings = false
            shelters = []
            petSitters = []
            conversations = []
            myListings = []
            myReports = []
            notificationPreferences = NotificationPreferences()
            mapMarkers = []
            isLoading = false
            errorMessage = userFacingMessage(for: error, fallback: "Не удалось загрузить данные. Проверьте интернет и попробуйте еще раз.")
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

    func showMyListings() {
        selectedTab = .profile
        path.append(.myListings)
    }

    func showMyReports() {
        selectedTab = .profile
        path.append(.myReports)
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
        Task {
            await loadConversationMessagesIfNeeded(conversation.id)
        }
    }

    func startChat(for listing: Listing) {
        guard listing.canReceiveMessages, !isOwnListing(listing) else { return }

        if let conversation = conversations.first(where: { $0.listingTitle == listing.title }) {
            showConversation(conversation)
        } else {
            Task {
                await performAction {
                    let conversation = try await marketplaceService.createConversation(for: listing.id)
                    conversations.insert(conversation, at: 0)
                    loadedConversationMessageIDs.insert(conversation.id)
                    selectedTab = .chats
                    path.append(.conversation(conversation.id))
                }
            }
        }
    }

    func listing(withID id: String) -> Listing? {
        listings.first { $0.id == id } ?? myListings.first { $0.id == id }
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
        let previousLastMessage = conversations[index].lastMessage
        let previousTime = conversations[index].time
        let previousUnreadCount = conversations[index].unreadCount
        let outgoing = ChatMessage(
            id: pendingID,
            senderID: session?.user.id,
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
                if let currentIndex = conversations.firstIndex(where: { $0.id == conversationID }) {
                    let pendingIsStillLast = conversations[currentIndex].messages.last?.id == pendingID
                    conversations[currentIndex].messages.removeAll(where: { $0.id == pendingID })
                    if pendingIsStillLast {
                        conversations[currentIndex].lastMessage = previousLastMessage
                        conversations[currentIndex].time = previousTime
                        conversations[currentIndex].unreadCount = previousUnreadCount
                    }
                }
                errorMessage = String(localized: "marketplace_action_error")
            }
        }
    }

    func sendPhotoMessage(data: Data, in conversationID: String) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }

        let now = String(localized: "chat_now")
        let pendingID = "pending-\(UUID().uuidString)"
        let previousLastMessage = conversations[index].lastMessage
        let previousTime = conversations[index].time
        let previousUnreadCount = conversations[index].unreadCount
        let outgoingPlaceholder = ChatMessage(
            id: pendingID,
            senderID: session?.user.id,
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
                    let pendingIsStillLast = conversations[currentIndex].messages.last?.id == pendingID
                    conversations[currentIndex].messages.removeAll(where: { $0.id == pendingID })
                    if pendingIsStillLast {
                        conversations[currentIndex].lastMessage = previousLastMessage
                        conversations[currentIndex].time = previousTime
                        conversations[currentIndex].unreadCount = previousUnreadCount
                    }
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
            var submission = draft
            if !draft.photoData.isEmpty {
                var uploads: [ListingPhotoUpload] = []
                for data in draft.photoData {
                    let uuidString = UUID().uuidString
                    let upload = try await mediaService.uploadListingPhoto(
                        data: data,
                        fileName: "\(uuidString).jpg",
                        mimeType: "image/jpeg"
                    )
                    uploads.append(upload)
                }
                submission.photoIds = uploads.map(\.mediaId)
            }
            let listing = try await marketplaceService.createListing(from: submission)
            favoriteListingIDs.remove(listing.id)
            upsertMyListing(listing)
            selectedTab = .profile
            activeSheet = nil
            path.append(.myListings)
        }
    }

    func refreshMyListings() async {
        do {
            myListings = try await marketplaceService.fetchMyListings()
        } catch {
            errorMessage = userFacingMessage(for: error, fallback: "Не удалось обновить ваши объявления.")
        }
    }

    func showEditListing(_ listing: Listing) {
        activeSheet = .editListing(listing)
    }

    func showReportListing(_ listing: Listing) {
        guard !isOwnListing(listing) else { return }
        activeSheet = .reportListing(listing)
    }

    func updateListing(_ listing: Listing, draft: ListingEditDraft) async {
        guard draft.isValid else { return }

        await performAction {
            let updated = try await marketplaceService.updateListing(id: listing.id, draft: draft)
            replaceListing(updated)
            activeSheet = nil
        }
    }

    func closeListing(_ listing: Listing) {
        Task {
            await performAction {
                let updated = try await marketplaceService.closeListing(id: listing.id)
                replaceListing(updated)
            }
        }
    }

    func deleteListing(_ listing: Listing) {
        Task {
            await performAction {
                try await marketplaceService.deleteListing(id: listing.id)
                myListings.removeAll { $0.id == listing.id }
                listings.removeAll { $0.id == listing.id }
                favoriteListingIDs.remove(listing.id)
                path.removeAll { route in
                    if case let .listingDetail(id) = route {
                        return id == listing.id
                    }
                    return false
                }
            }
        }
    }

    func isOwnListing(_ listing: Listing) -> Bool {
        if myListings.contains(where: { $0.id == listing.id }) {
            return true
        }
        return listing.ownerID == session?.user.id
    }

    func reportListing(_ listing: Listing, draft: ListingReportDraft) async {
        guard draft.isValid, !isOwnListing(listing) else { return }

        await performAction {
            let report = try await marketplaceService.reportListing(id: listing.id, draft: draft)
            upsertReport(report)
            activeSheet = .status(title: "Жалоба отправлена", message: "Спасибо. Модераторы проверят объявление и примут решение.")
        }
    }

    func showReportUser(in conversation: Conversation) {
        guard let userID = conversation.otherParticipantID else { return }
        activeSheet = .reportTarget(
            ReportTarget(
                type: .user,
                id: userID,
                title: "Пожаловаться на пользователя",
                subtitle: conversation.name
            )
        )
    }

    func blockUser(in conversation: Conversation) async {
        guard let userID = conversation.otherParticipantID else { return }

        await performAction {
            try await marketplaceService.blockUser(userID: userID)
            blockedUsers = try await marketplaceService.fetchBlockedUsers()
            conversations.removeAll { $0.id == conversation.id || $0.otherParticipantID == userID }
            path.removeAll { route in
                if case let .conversation(id) = route {
                    return id == conversation.id
                }
                return false
            }
            activeSheet = .status(title: "Пользователь заблокирован", message: "Диалог скрыт. Новые сообщения между вами больше не будут доставляться.")
        }
    }

    func refreshBlockedUsers() async {
        do {
            blockedUsers = try await marketplaceService.fetchBlockedUsers()
        } catch {
            errorMessage = userFacingMessage(for: error, fallback: "Не удалось загрузить список блокировок.")
        }
    }

    func unblockUser(_ blockedUser: BlockedUser) async {
        await performAction {
            try await marketplaceService.unblockUser(userID: blockedUser.userID)
            blockedUsers.removeAll { $0.userID == blockedUser.userID }
        }
    }

    func showReportMessage(_ message: ChatMessage, in conversation: Conversation) {
        guard message.sender == .them else { return }
        activeSheet = .reportTarget(
            ReportTarget(
                type: .message,
                id: message.id,
                title: "Пожаловаться на сообщение",
                subtitle: message.text
            )
        )
    }

    func reportTarget(_ target: ReportTarget, draft: ReportDraft) async {
        guard draft.isValid else { return }

        await performAction {
            let report = try await marketplaceService.report(targetType: target.type, targetID: target.id, draft: draft)
            upsertReport(report)
            activeSheet = .status(title: "Жалоба отправлена", message: target.successMessage)
        }
    }

    func refreshMyReports() async {
        do {
            myReports = try await marketplaceService.fetchMyReports()
        } catch {
            errorMessage = userFacingMessage(for: error, fallback: "Не удалось обновить обращения.")
        }
    }

    func updateNotificationPreferences(_ preferences: NotificationPreferences) async {
        let previous = notificationPreferences
        notificationPreferences = preferences

        do {
            notificationPreferences = try await marketplaceService.updateNotificationPreferences(preferences)
        } catch {
            notificationPreferences = previous
            errorMessage = userFacingMessage(for: error, fallback: "Не удалось сохранить настройки уведомлений.")
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
                loadedConversationMessageIDs.insert(conversation.id)
                selectedTab = .chats
                path.append(.conversation(conversation.id))
            }
        }
    }

    func showProfileAction(_ action: ProfileMenuAction) {
        if action == .listings {
            showMyListings()
        } else if action == .reports {
            showMyReports()
        } else {
            activeSheet = .profileAction(action)
            if action == .security {
                Task {
                    await refreshBlockedUsers()
                }
            }
        }
    }

    func requestProfileVerification(message: String? = nil) async {
        await performAction {
            profileVerification = try await marketplaceService.requestProfileVerification(message: message)
            activeSheet = .status(title: "Заявка отправлена", message: "Модераторы проверят профиль. Статус появится в профиле.")
        }
    }

    func showVerificationRequest() {
        activeSheet = .verificationRequest
    }

    func signOut() {
        webSocketService.disconnect()
        coordinator?.signOut(allDevices: false)
    }

    func signOutEverywhere() {
        webSocketService.disconnect()
        coordinator?.signOut(allDevices: true)
    }

    func deleteAccount() async {
        await performAction {
            try await marketplaceService.deleteAccount()
            webSocketService.disconnect()
            coordinator?.signOut(allDevices: true)
        }
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
            errorMessage = userFacingMessage(for: error, fallback: String(localized: "marketplace_action_error"))
        }
    }

    private func upsertMyListing(_ listing: Listing) {
        if let index = myListings.firstIndex(where: { $0.id == listing.id }) {
            myListings[index] = listing
        } else {
            myListings.insert(listing, at: 0)
        }
    }

    private func replaceListing(_ listing: Listing) {
        upsertMyListing(listing)
        if let index = listings.firstIndex(where: { $0.id == listing.id }) {
            listings[index] = listing
        }
    }

    private func upsertReport(_ report: ReportResponse) {
        if let index = myReports.firstIndex(where: { $0.id == report.id }) {
            myReports[index] = report
        } else {
            myReports.insert(report, at: 0)
        }
    }

    func loadConversationMessagesIfNeeded(_ conversationID: String) async {
        guard !loadedConversationMessageIDs.contains(conversationID),
              conversations.contains(where: { $0.id == conversationID })
        else { return }

        do {
            let messages = try await marketplaceService.fetchMessages(conversationID: conversationID)
            if let index = conversations.firstIndex(where: { $0.id == conversationID }) {
                conversations[index].messages = mergeMessages(existing: conversations[index].messages, fetched: messages)
                loadedConversationMessageIDs.insert(conversationID)
            }
        } catch {
            errorMessage = userFacingMessage(for: error, fallback: "Не удалось загрузить сообщения.")
        }
    }

    private func mergeConversationSummaries(_ fetched: [Conversation]) -> [Conversation] {
        fetched.map { conversation in
            guard let existing = conversations.first(where: { $0.id == conversation.id }) else {
                return conversation
            }
            var merged = conversation
            merged.messages = existing.messages
            return merged
        }
    }

    private func mergeMessages(existing: [ChatMessage], fetched: [ChatMessage]) -> [ChatMessage] {
        var seen = Set(fetched.map(\.id))
        var merged = fetched
        for message in existing where !seen.contains(message.id) {
            merged.append(message)
            seen.insert(message.id)
        }
        return merged
    }

    private func userFacingMessage(for error: Error, fallback: String) -> String {
        if let localizedError = error as? LocalizedError,
           let message = localizedError.errorDescription,
           !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return message
        }

        if error is URLError {
            return "Не удалось подключиться к серверу. Проверьте интернет и попробуйте еще раз."
        }

        return fallback
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
            senderID: message.senderId,
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
            self.conversations = mergeConversationSummaries(fetched)
        } catch {
            Self.logger.error("Failed to refresh conversations: \(String(describing: error), privacy: .private)")
        }
    }
}
