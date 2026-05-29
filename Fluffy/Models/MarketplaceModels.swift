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
    var latitude: Double? = nil
    var longitude: Double? = nil
    var radius: Double? = nil

    static let firstPage = ListingQuery(
        category: nil,
        searchText: "",
        page: 1,
        pageSize: 20,
        latitude: 52.60,
        longitude: 39.57
    )
}

struct ListingDraft: Hashable {
    var publicationType: PublicationType = .adoption
    var publicationFormat: PublicationFormat = .nonCommercial
    var urgencyLevel: PublicationUrgency = .normal
    var category: ListingCategory = .rehome
    var title = ""
    var animalType: AnimalType = .dog
    var petName = ""
    var breed = ""
    var age = ""
    var sex: PetSex = .male
    var city = ""
    var district = ""
    var location = ""
    var description = ""
    var contactDetails = ""
    var contactMethod: ContactMethod = .chat
    var pricePerDay: Int?
    var reward: Int?
    var isUrgent = false
    var photoIds: [String] = []
    var photoData: [Data] = []

    var helpKinds: Set<HelpKind> = []
    var helpUrgency: HelpUrgency = .today
    var fundraisingGoal = ""
    var documentsNote = ""
    var alarmEnabled = true

    var listingSubtype: ListingSubtype = .giveAway
    var pricingMode: PricingMode = .free
    var saleTerms = ""
    var deliveryOptions = ""

    var adoptionReason = ""
    var transferTerms = ""
    var familyWithKids: BooleanChoice = .unknown
    var otherPets: BooleanChoice = .unknown
    var homePreference: HomePreference = .any
    var isSterilized = false
    var isVaccinated = false
    var requiresInterview = true

    var lostFoundMode: LostFoundMode = .lost
    var eventDate = Date()
    var eventPlace = ""
    var distinctiveFeatures = ""
    var hasCollarOrChip = false
    var needsUrgentCare = false

    var sittingMode: SittingMode = .needHelp
    var dates = ""
    var duration = ""
    var conditions = ""
    var petSpecialNeeds = ""

    var isValid: Bool {
        let hasBase = !title.trimmed.isEmpty
            && !location.trimmed.isEmpty
            && !description.trimmed.isEmpty
        guard hasBase else { return false }

        if publicationFormat == .commercial, pricingMode == .fixed, pricePerDay == nil {
            return false
        }

        switch publicationType {
        case .urgentHelp:
            return !helpKinds.isEmpty
        case .lostFound:
            return !distinctiveFeatures.trimmed.isEmpty || !eventPlace.trimmed.isEmpty
        case .petSitting:
            return !dates.trimmed.isEmpty || !conditions.trimmed.isEmpty
        case .listing, .adoption:
            return true
        }
    }

    var resolvedCategory: ListingCategory {
        switch publicationType {
        case .urgentHelp:
            .volunteer
        case .listing:
            .rehome
        case .lostFound:
            lostFoundMode == .lost ? .lost : .found
        case .adoption:
            .rehome
        case .petSitting:
            sittingMode == .needHelp ? .boardingNeeded : .boardingOffer
        }
    }

    var normalizedCity: String {
        let explicitCity = city.trimmed
        if !explicitCity.isEmpty { return explicitCity }
        return location.components(separatedBy: ",").first?.trimmed ?? location.trimmed
    }

    var normalizedLocation: String {
        let parts = [city, district, location].map(\.trimmed).filter { !$0.isEmpty }
        return parts.isEmpty ? location.trimmed : parts.joined(separator: ", ")
    }

    var tags: [String] {
        var values = [
            publicationType.title,
            publicationFormat.title,
            urgencyLevel.title,
            contactMethod.title
        ]
        values.append(contentsOf: helpKinds.map(\.title).sorted())
        values.append(listingSubtype.title)
        values.append(pricingMode.title)
        values.append(homePreference.title)
        values.append(lostFoundMode.title)
        values.append(sittingMode.title)
        if isSterilized { values.append("Стерилизован") }
        if isVaccinated { values.append("Вакцинирован") }
        if hasCollarOrChip { values.append("Ошейник / чип") }
        if needsUrgentCare { values.append("Нужна срочная помощь") }
        return Array(Set(values.filter { !$0.trimmed.isEmpty })).sorted()
    }

    var submissionDescription: String {
        var lines = [description.trimmed]
        var details: [String] = [
            "Тип публикации: \(publicationType.title)",
            "Формат: \(publicationFormat.title)",
            "Срочность: \(urgencyLevel.title)"
        ]

        if !petName.trimmed.isEmpty { details.append("Имя питомца: \(petName.trimmed)") }
        if !contactDetails.trimmed.isEmpty { details.append("Контакты: \(contactDetails.trimmed)") }
        details.append("Связь: \(contactMethod.title)")

        switch publicationType {
        case .urgentHelp:
            details.append("Вид помощи: \(helpKinds.map(\.title).sorted().joined(separator: ", "))")
            details.append("Насколько срочно: \(helpUrgency.title)")
            if let reward { details.append("Сумма сбора: \(reward) ₽") }
            if !fundraisingGoal.trimmed.isEmpty { details.append("Цель сбора: \(fundraisingGoal.trimmed)") }
            if !documentsNote.trimmed.isEmpty { details.append("Документы: \(documentsNote.trimmed)") }
            if alarmEnabled { details.append("Метка: Тревога") }
        case .listing:
            details.append("Подтип: \(listingSubtype.title)")
            if !saleTerms.trimmed.isEmpty { details.append("Условия: \(saleTerms.trimmed)") }
            if !deliveryOptions.trimmed.isEmpty { details.append("Доставка / самовывоз: \(deliveryOptions.trimmed)") }
        case .adoption:
            if !adoptionReason.trimmed.isEmpty { details.append("Причина пристройства: \(adoptionReason.trimmed)") }
            if !transferTerms.trimmed.isEmpty { details.append("Условия передачи: \(transferTerms.trimmed)") }
            details.append("С детьми: \(familyWithKids.title)")
            details.append("С другими животными: \(otherPets.title)")
            details.append("Дом: \(homePreference.title)")
            details.append("Собеседование / договор: \(requiresInterview ? "да" : "нет")")
        case .lostFound:
            details.append("Статус: \(lostFoundMode.title)")
            details.append("Дата: \(Self.dateFormatter.string(from: eventDate))")
            if !eventPlace.trimmed.isEmpty { details.append("Место: \(eventPlace.trimmed)") }
            if !distinctiveFeatures.trimmed.isEmpty { details.append("Приметы: \(distinctiveFeatures.trimmed)") }
        case .petSitting:
            details.append("Режим: \(sittingMode.title)")
            if !dates.trimmed.isEmpty { details.append("Даты: \(dates.trimmed)") }
            if !duration.trimmed.isEmpty { details.append("Длительность: \(duration.trimmed)") }
            if !conditions.trimmed.isEmpty { details.append("Условия: \(conditions.trimmed)") }
            if !petSpecialNeeds.trimmed.isEmpty { details.append("Особенности питомца: \(petSpecialNeeds.trimmed)") }
        }

        if let pricePerDay {
            details.append(publicationType == .petSitting ? "Цена: \(pricePerDay) ₽" : "Стоимость: \(pricePerDay) ₽")
        } else if publicationFormat == .nonCommercial || pricingMode == .free {
            details.append("Стоимость: бесплатно")
        } else if pricingMode == .negotiable {
            details.append("Стоимость: договорная")
        }

        lines.append("")
        lines.append("Дополнительные данные:")
        lines.append(contentsOf: details)
        return lines.joined(separator: "\n")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        return formatter
    }()
}

enum PublicationType: String, CaseIterable, Identifiable, Hashable {
    case urgentHelp
    case listing
    case lostFound
    case adoption
    case petSitting

    var id: String { rawValue }

    var title: String {
        switch self {
        case .urgentHelp: "Срочная помощь"
        case .listing: "Объявление"
        case .lostFound: "Потерялся / найден"
        case .adoption: "Пристройство"
        case .petSitting: "Передержка / pet-sitting"
        }
    }

    var subtitle: String {
        switch self {
        case .urgentHelp: "Сбор, корм, лекарства, транспорт"
        case .listing: "Отдам, продам, услуги или аксессуары"
        case .lostFound: "Поиск или найденный питомец"
        case .adoption: "В добрые руки с условиями"
        case .petSitting: "Нужна помощь или предлагаю услугу"
        }
    }

    var icon: String {
        switch self {
        case .urgentHelp: "cross.case.fill"
        case .listing: "pawprint.fill"
        case .lostFound: "magnifyingglass"
        case .adoption: "house.fill"
        case .petSitting: "dog.fill"
        }
    }
}

enum PublicationFormat: String, CaseIterable, Identifiable, Hashable {
    case nonCommercial
    case commercial

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nonCommercial: "Некоммерческое"
        case .commercial: "Коммерческое"
        }
    }
}

enum PublicationUrgency: String, CaseIterable, Identifiable, Hashable {
    case normal
    case urgent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: "Обычная"
        case .urgent: "Срочная"
        }
    }
}

enum HelpKind: String, CaseIterable, Identifiable, Hashable {
    case money
    case food
    case medicine
    case foster
    case transport
    case volunteer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .money: "Деньги"
        case .food: "Корм"
        case .medicine: "Лекарства"
        case .foster: "Передержка"
        case .transport: "Транспорт"
        case .volunteer: "Волонтер"
        }
    }
}

enum HelpUrgency: String, CaseIterable, Identifiable, Hashable {
    case today
    case threeDays
    case notUrgent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Сегодня"
        case .threeDays: "В течение 3 дней"
        case .notUrgent: "Не срочно"
        }
    }
}

enum ListingSubtype: String, CaseIterable, Identifiable, Hashable {
    case giveAway
    case sell
    case lookingOwner
    case breeding
    case accessories

    var id: String { rawValue }

    var title: String {
        switch self {
        case .giveAway: "Отдам"
        case .sell: "Продам"
        case .lookingOwner: "Ищу хозяина"
        case .breeding: "Вязка"
        case .accessories: "Аксессуары / услуги"
        }
    }
}

enum PricingMode: String, CaseIterable, Identifiable, Hashable {
    case free
    case fixed
    case negotiable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free: "Бесплатно"
        case .fixed: "Фиксированная цена"
        case .negotiable: "Договорная"
        }
    }
}

enum BooleanChoice: String, CaseIterable, Identifiable, Hashable {
    case yes
    case no
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yes: "Да"
        case .no: "Нет"
        case .unknown: "Не знаю"
        }
    }
}

enum HomePreference: String, CaseIterable, Identifiable, Hashable {
    case any
    case apartment
    case house

    var id: String { rawValue }

    var title: String {
        switch self {
        case .any: "Любой дом"
        case .apartment: "Квартира"
        case .house: "Частный дом"
        }
    }
}

enum LostFoundMode: String, CaseIterable, Identifiable, Hashable {
    case lost
    case found

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lost: "Потерялся"
        case .found: "Найден"
        }
    }
}

enum SittingMode: String, CaseIterable, Identifiable, Hashable {
    case needHelp
    case offerService

    var id: String { rawValue }

    var title: String {
        switch self {
        case .needHelp: "Мне нужна помощь"
        case .offerService: "Я предлагаю услугу"
        }
    }
}

enum ContactMethod: String, CaseIterable, Identifiable, Hashable {
    case chat
    case phone
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chat: "Чат Fluffy"
        case .phone: "Телефон"
        case .both: "Чат и телефон"
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
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
    let distance: Double?

    init(
        id: String,
        category: ListingCategory,
        title: String,
        animalType: AnimalType,
        breed: String,
        age: String,
        sex: PetSex,
        location: String,
        imageURL: URL?,
        description: String,
        authorName: String,
        authorAvatarURL: URL?,
        date: String,
        tags: [String],
        isUrgent: Bool,
        pricePerDay: Int?,
        isFavorite: Bool = false,
        distance: Double? = nil
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.animalType = animalType
        self.breed = breed
        self.age = age
        self.sex = sex
        self.location = location
        self.imageURL = imageURL
        self.description = description
        self.authorName = authorName
        self.authorAvatarURL = authorAvatarURL
        self.date = date
        self.tags = tags
        self.isUrgent = isUrgent
        self.pricePerDay = pricePerDay
        self.isFavorite = isFavorite
        self.distance = distance
    }

    var city: String {
        location.components(separatedBy: ",").first ?? location
    }

    var distanceText: String? {
        guard let distance else { return nil }
        if distance < 1000 {
            return "\(Int(distance)) м"
        } else {
            return String(format: "%.1f км", distance / 1000.0)
        }
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
