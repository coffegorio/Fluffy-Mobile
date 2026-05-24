//
//  MarketplaceServicing.swift
//  Fluffy
//

protocol MarketplaceServicing {
    func fetchListings(query: ListingQuery) async throws -> MarketplacePage<Listing>
    func fetchShelters() async throws -> [Shelter]
    func fetchPetSitters() async throws -> [PetSitter]
    func fetchConversations() async throws -> [Conversation]
    func fetchUserProfile() async throws -> UserProfile
    func createListing(from draft: ListingDraft) async throws -> Listing
    func setFavorite(listingID: String, isFavorite: Bool) async throws
    func createConversation(for listingID: String) async throws -> Conversation
    func sendMessage(_ text: String, in conversationID: String) async throws -> ChatMessage
    func updateUserProfile(_ draft: UserProfileDraft) async throws -> UserProfile
    func requestShelterHelp(_ request: ShelterHelpRequest) async throws
    func contactPetSitter(_ request: PetSitterContactRequest) async throws -> Conversation
}
