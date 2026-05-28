//
//  MarketplaceModels.swift
//  Fluffy
//

import Foundation
import SwiftUI

struct MarketplacePage<Item> {
    let items: [Item]
    let page: Int
    let pageSize: Int
    let hasMore: Bool
}

struct ListingQuery: Hashable {
    var category: ListingCategory?
    var searchText: String
    var page: Int
    var pageSize: Int

    static let firstPage = ListingQuery(
        category: nil,
        searchText: "",
        page: 1,
        pageSize: 20
    )
}

struct ListingDraft: Hashable {
    var category: ListingCategory = .rehome
    var title = ""
    var animalType: AnimalType = .dog
    var breed = ""
    var age = ""
    var sex: PetSex = .male
    var location = ""
    var description = ""
    var pricePerDay: Int?
    var isUrgent = false

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !breed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct UserProfileDraft: Hashable {
    var name: String
    var handle: String
    var city: String
    var phone: String
    var avatarURL: URL?

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct ProfileVerificationResponse: Hashable {
    let status: VerificationStatus
    let latestRequestId: String?
    let updatedAt: Date?
}

struct ShelterHelpRequest: Hashable {
    let shelterID: String
    let message: String
}

struct PetSitterContactRequest: Hashable {
    let petSitterID: String
    let message: String
}

enum ListingCategory: String, CaseIterable, Identifiable, Hashable {
    case all
    case rehome
    case lost
    case found
    case boardingNeeded
    case boardingOffer
    case petsitting
    case volunteer

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all: "category_all"
        case .rehome: "category_rehome"
        case .lost: "category_lost"
        case .found: "category_found"
        case .boardingNeeded: "category_boarding_needed"
        case .boardingOffer: "category_boarding_offer"
        case .petsitting: "category_petsitting"
        case .volunteer: "category_volunteer"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "pawprint.fill"
        case .rehome: "house.fill"
        case .lost: "magnifyingglass"
        case .found: "checkmark.circle.fill"
        case .boardingNeeded: "house.and.flag.fill"
        case .boardingOffer: "bed.double.fill"
        case .petsitting: "figure.walk"
        case .volunteer: "hands.sparkles.fill"
        }
    }

    var tint: Color {
        switch self {
        case .all, .rehome: AppTheme.accent
        case .lost: AppTheme.danger
        case .found: AppTheme.success
        case .boardingNeeded: AppTheme.purple
        case .boardingOffer: AppTheme.blue
        case .petsitting: AppTheme.amber
        case .volunteer: Color.pink
        }
    }

    var softTint: Color {
        switch self {
        case .lost: Color.red.opacity(0.10)
        case .found: Color.green.opacity(0.10)
        case .boardingNeeded: Color.purple.opacity(0.10)
        case .boardingOffer: Color.blue.opacity(0.10)
        case .petsitting: Color.yellow.opacity(0.16)
        case .volunteer: Color.pink.opacity(0.10)
        case .all, .rehome: AppTheme.accentSoft
        }
    }
}

enum AnimalType: String, CaseIterable, Identifiable, Hashable {
    case dog
    case cat
    case rabbit
    case hamster
    case bird
    case other

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .dog: "dog.fill"
        case .cat: "cat.fill"
        case .rabbit: "hare.fill"
        case .hamster: "circle.hexagongrid.fill"
        case .bird: "bird.fill"
        case .other: "pawprint.fill"
        }
    }
}

enum PetSex: String, CaseIterable, Identifiable, Hashable {
    case male
    case female

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .male: "pet_sex_male"
        case .female: "pet_sex_female"
        }
    }
}

struct Listing: Identifiable, Hashable {
    let id: String
    let category: ListingCategory
    let title: String
    let animalType: AnimalType
    let breed: String
    let age: String
    let sex: PetSex
    let location: String
    let imageURL: URL?
    let description: String
    let authorName: String
    let authorAvatarURL: URL?
    let date: String
    let tags: [String]
    let isUrgent: Bool
    let pricePerDay: Int?
    var isFavorite: Bool = false

    var city: String {
        location.components(separatedBy: ",").first ?? location
    }
}

struct Shelter: Identifiable, Hashable {
    let id: String
    let name: String
    let city: String
    let imageURL: URL?
    let animals: Int
    let description: String
    let phone: String
    let urgentCount: Int
}

struct PetSitter: Identifiable, Hashable {
    let id: String
    let name: String
    let avatarURL: URL?
    let rating: Double
    let reviews: Int
    let pricePerDay: Int
    let location: String
    let services: [String]
    let bio: String
    let animalTypes: [AnimalType]
}

struct ChatMessage: Identifiable, Hashable {
    enum Sender: Hashable {
        case me
        case them
    }

    let id: String
    let text: String
    let sender: Sender
    let time: String
}

struct Conversation: Identifiable, Hashable {
    let id: String
    let name: String
    let avatarURL: URL?
    var lastMessage: String
    var time: String
    var unreadCount: Int
    let listingTitle: String
    var messages: [ChatMessage]
}

struct UserProfile: Hashable {
    let name: String
    let handle: String
    let city: String
    let email: String
    let phone: String
    let avatarURL: URL?
    let rating: Double
    let reviews: Int
    let listingsCount: Int
    let dealsCount: Int
    let daysOnPlatform: Int

    var draft: UserProfileDraft {
        UserProfileDraft(name: name, handle: handle, city: city, phone: phone, avatarURL: avatarURL)
    }
}
