//
//  MarketplaceServicing.swift
//  Fluffy
//

protocol MarketplaceServicing {
    func fetchListings(query: ListingQuery) async throws -> MarketplacePage<Listing>
    func fetchShelters(citySlug: String?) async throws -> [Shelter]
    func fetchPetSitters(citySlug: String?) async throws -> [PetSitter]
    func fetchConversations() async throws -> [Conversation]
    func fetchMessages(conversationID: String) async throws -> [ChatMessage]
    func fetchUserProfile() async throws -> UserProfile
    func fetchMyListings() async throws -> [Listing]
    func createListing(from draft: ListingDraft) async throws -> Listing
    func updateListing(id: String, draft: ListingEditDraft) async throws -> Listing
    func closeListing(id: String) async throws -> Listing
    func deleteListing(id: String) async throws
    func setFavorite(listingID: String, isFavorite: Bool) async throws
    func createConversation(for listingID: String) async throws -> Conversation
    func sendMessage(_ text: String, in conversationID: String) async throws -> ChatMessage
    func markRead(conversationID: String) async throws
    func updateUserProfile(_ draft: UserProfileDraft) async throws -> UserProfile
    func deleteAccount() async throws
    func requestProfileVerification(message: String?) async throws -> ProfileVerificationResponse
    func fetchProfileVerificationStatus() async throws -> ProfileVerificationResponse
    func fetchNotificationPreferences() async throws -> NotificationPreferences
    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws -> NotificationPreferences
    func registerPushDevice(token: String, deviceID: String, environment: PushEnvironment) async throws -> PushDevice
    func unregisterPushDevice(deviceID: String) async throws -> PushDevice
    func fetchBlockedUsers() async throws -> [BlockedUser]
    func blockUser(userID: String) async throws
    func unblockUser(userID: String) async throws
    func report(targetType: ReportTargetType, targetID: String, draft: ReportDraft) async throws -> ReportResponse
    func reportListing(id: String, draft: ListingReportDraft) async throws -> ReportResponse
    func fetchMyReports() async throws -> [ReportResponse]
    func requestShelterHelp(_ request: ShelterHelpRequest) async throws
    func contactPetSitter(_ request: PetSitterContactRequest) async throws -> Conversation
}
