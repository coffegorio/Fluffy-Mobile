//
//  MockMarketplaceService.swift
//  Fluffy
//

import Foundation

struct MockMarketplaceService: MarketplaceServicing {
    func fetchListings(query: ListingQuery) async throws -> MarketplacePage<Listing> {
        try await simulateLatency()
        let normalizedQuery = query.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = MockMarketplaceData.listings.filter { listing in
            let matchesCategory = query.category == nil || query.category == .all || listing.category == query.category
            let matchesSearch = normalizedQuery.isEmpty
                || listing.title.lowercased().contains(normalizedQuery)
                || listing.breed.lowercased().contains(normalizedQuery)
                || listing.location.lowercased().contains(normalizedQuery)

            return matchesCategory && matchesSearch
        }
        let startIndex = max(0, (query.page - 1) * query.pageSize)
        let endIndex = min(filtered.count, startIndex + query.pageSize)
        let items = startIndex < endIndex ? Array(filtered[startIndex..<endIndex]) : []

        return MarketplacePage(
            items: items,
            page: query.page,
            pageSize: query.pageSize,
            hasMore: endIndex < filtered.count
        )
    }

    func fetchShelters() async throws -> [Shelter] {
        try await simulateLatency()
        return MockMarketplaceData.shelters
    }

    func fetchPetSitters() async throws -> [PetSitter] {
        try await simulateLatency()
        return MockMarketplaceData.petSitters
    }

    func fetchConversations() async throws -> [Conversation] {
        try await simulateLatency()
        return MockMarketplaceData.conversations
    }

    func fetchMessages(conversationID: String) async throws -> [ChatMessage] {
        try await simulateLatency()
        return MockMarketplaceData.conversations.first { $0.id == conversationID }?.messages ?? []
    }

    func fetchUserProfile() async throws -> UserProfile {
        try await simulateLatency()
        return MockMarketplaceData.profile
    }

    func fetchMyListings() async throws -> [Listing] {
        try await simulateLatency()
        return MockMarketplaceData.myListings
    }

    func createListing(from draft: ListingDraft) async throws -> Listing {
        try await simulateLatency()
        return Listing(
            id: "local-\(UUID().uuidString)",
            ownerID: "mock-user",
            category: draft.resolvedCategory,
            status: .pending,
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            animalType: draft.animalType,
            breed: draft.breed.trimmingCharacters(in: .whitespacesAndNewlines),
            age: draft.age.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "-" : draft.age,
            sex: draft.sex,
            location: draft.location.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: nil,
            description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
            authorName: MockMarketplaceData.profile.name,
            authorAvatarURL: MockMarketplaceData.profile.avatarURL,
            date: String(localized: "chat_now"),
            tags: [],
            isUrgent: draft.isUrgent,
            pricePerDay: draft.pricePerDay
        )
    }

    func updateListing(id: String, draft: ListingEditDraft) async throws -> Listing {
        try await simulateLatency()
        let existing = MockMarketplaceData.myListings.first { $0.id == id } ?? MockMarketplaceData.listings.first { $0.id == id }
        return Listing(
            id: id,
            ownerID: existing?.ownerID ?? "mock-user",
            category: existing?.category ?? .rehome,
            status: existing?.status ?? .pending,
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            animalType: existing?.animalType ?? .dog,
            breed: existing?.breed ?? "-",
            age: existing?.age ?? "-",
            sex: existing?.sex ?? .male,
            location: draft.location.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: existing?.imageURL,
            description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
            authorName: existing?.authorName ?? MockMarketplaceData.profile.name,
            authorAvatarURL: existing?.authorAvatarURL ?? MockMarketplaceData.profile.avatarURL,
            date: existing?.date ?? String(localized: "chat_now"),
            tags: existing?.tags ?? [],
            isUrgent: draft.isUrgent,
            pricePerDay: draft.pricePerDay,
            isFavorite: existing?.isFavorite ?? false,
            distance: existing?.distance
        )
    }

    func closeListing(id: String) async throws -> Listing {
        try await simulateLatency()
        let existing = MockMarketplaceData.myListings.first { $0.id == id } ?? MockMarketplaceData.listings.first { $0.id == id }
        return Listing(
            id: id,
            ownerID: existing?.ownerID ?? "mock-user",
            category: existing?.category ?? .rehome,
            status: .closed,
            title: existing?.title ?? "Закрытое объявление",
            animalType: existing?.animalType ?? .dog,
            breed: existing?.breed ?? "-",
            age: existing?.age ?? "-",
            sex: existing?.sex ?? .male,
            location: existing?.location ?? MockMarketplaceData.profile.city,
            imageURL: existing?.imageURL,
            description: existing?.description ?? "",
            authorName: existing?.authorName ?? MockMarketplaceData.profile.name,
            authorAvatarURL: existing?.authorAvatarURL ?? MockMarketplaceData.profile.avatarURL,
            date: existing?.date ?? String(localized: "chat_now"),
            tags: existing?.tags ?? [],
            isUrgent: existing?.isUrgent ?? false,
            pricePerDay: existing?.pricePerDay,
            isFavorite: false,
            distance: existing?.distance
        )
    }

    func deleteListing(id: String) async throws {
        try await simulateLatency()
    }

    func setFavorite(listingID: String, isFavorite: Bool) async throws {
        try await simulateLatency()
    }

    func createConversation(for listingID: String) async throws -> Conversation {
        try await simulateLatency()
        let listing = MockMarketplaceData.listings.first { $0.id == listingID }
        return Conversation(
            id: "conversation-\(listingID)",
            name: listing?.authorName ?? String(localized: "chat_unknown_user"),
            avatarURL: listing?.authorAvatarURL,
            lastMessage: String(localized: "chat_new_conversation_message"),
            time: String(localized: "chat_now"),
            unreadCount: 0,
            listingTitle: listing?.title ?? String(localized: "add_listing"),
            otherParticipantID: listing?.ownerID ?? "mock-owner",
            messages: [
                ChatMessage(
                    id: "message-\(UUID().uuidString)",
                    senderID: "tester@example.com",
                    text: String(localized: "chat_new_conversation_message"),
                    sender: .me,
                    time: String(localized: "chat_now")
                )
            ]
        )
    }

    func sendMessage(_ text: String, in conversationID: String) async throws -> ChatMessage {
        try await simulateLatency()
        return ChatMessage(
            id: "message-\(UUID().uuidString)",
            senderID: "tester@example.com",
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            sender: .me,
            time: String(localized: "chat_now")
        )
    }

    func markRead(conversationID: String) async throws {
        try await simulateLatency()
    }

    func updateUserProfile(_ draft: UserProfileDraft) async throws -> UserProfile {
        try await simulateLatency()
        return UserProfile(
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            handle: draft.handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "@fluffy" : draft.handle,
            city: draft.city.trimmingCharacters(in: .whitespacesAndNewlines),
            email: MockMarketplaceData.profile.email,
            phone: draft.phone.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarURL: draft.avatarURL ?? MockMarketplaceData.profile.avatarURL,
            verificationStatus: MockMarketplaceData.profile.verificationStatus,
            rating: MockMarketplaceData.profile.rating,
            reviews: MockMarketplaceData.profile.reviews,
            listingsCount: MockMarketplaceData.profile.listingsCount,
            dealsCount: MockMarketplaceData.profile.dealsCount,
            daysOnPlatform: MockMarketplaceData.profile.daysOnPlatform
        )
    }

    func deleteAccount() async throws {
        try await simulateLatency()
    }

    func requestProfileVerification(message: String?) async throws -> ProfileVerificationResponse {
        try await simulateLatency()
        return ProfileVerificationResponse(status: .pending, latestRequestId: "mock-verification", updatedAt: Date())
    }

    func fetchProfileVerificationStatus() async throws -> ProfileVerificationResponse {
        try await simulateLatency()
        return ProfileVerificationResponse(status: .notStarted, latestRequestId: nil, updatedAt: nil)
    }

    func fetchNotificationPreferences() async throws -> NotificationPreferences {
        try await simulateLatency()
        return MockMarketplaceData.notificationPreferences
    }

    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws -> NotificationPreferences {
        try await simulateLatency()
        var updated = preferences
        updated.updatedAt = Date()
        return updated
    }

    func registerPushDevice(token: String, deviceID: String, environment: PushEnvironment) async throws -> PushDevice {
        try await simulateLatency()
        return PushDevice(id: "push-\(deviceID)", deviceID: deviceID, environment: environment, enabled: true)
    }

    func unregisterPushDevice(deviceID: String) async throws -> PushDevice {
        try await simulateLatency()
        return PushDevice(id: "push-\(deviceID)", deviceID: deviceID, environment: .sandbox, enabled: false)
    }

    func fetchBlockedUsers() async throws -> [BlockedUser] {
        try await simulateLatency()
        return []
    }

    func blockUser(userID: String) async throws {
        try await simulateLatency()
    }

    func unblockUser(userID: String) async throws {
        try await simulateLatency()
    }

    func report(targetType: ReportTargetType, targetID: String, draft: ReportDraft) async throws -> ReportResponse {
        try await simulateLatency()
        return ReportResponse(
            id: "report-\(UUID().uuidString)",
            targetType: targetType,
            targetID: targetID,
            reason: draft.reason.title,
            details: draft.details.trimmingCharacters(in: .whitespacesAndNewlines),
            status: .open,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func reportListing(id: String, draft: ListingReportDraft) async throws -> ReportResponse {
        try await report(targetType: .listing, targetID: id, draft: draft)
    }

    func fetchMyReports() async throws -> [ReportResponse] {
        try await simulateLatency()
        return MockMarketplaceData.reports
    }

    func requestShelterHelp(_ request: ShelterHelpRequest) async throws {
        try await simulateLatency()
    }

    func contactPetSitter(_ request: PetSitterContactRequest) async throws -> Conversation {
        try await simulateLatency()
        let sitter = MockMarketplaceData.petSitters.first { $0.id == request.petSitterID }
        return Conversation(
            id: "petsitter-\(request.petSitterID)",
            name: sitter?.name ?? String(localized: "petsitting_title"),
            avatarURL: sitter?.avatarURL,
            lastMessage: request.message,
            time: String(localized: "chat_now"),
            unreadCount: 0,
            listingTitle: String(localized: "petsitting_title"),
            otherParticipantID: request.petSitterID,
            messages: [
                ChatMessage(
                    id: "message-\(UUID().uuidString)",
                    senderID: "tester@example.com",
                    text: request.message,
                    sender: .me,
                    time: String(localized: "chat_now")
                )
            ]
        )
    }

    private func simulateLatency() async throws {
        let latency = ProcessInfo.processInfo.mockMarketplaceLatencyMilliseconds
        try await Task.sleep(nanoseconds: UInt64(latency) * 1_000_000)
    }
}

private extension ProcessInfo {
    var mockMarketplaceLatencyMilliseconds: Int {
        guard let index = arguments.firstIndex(of: "-MockMarketplaceLatencyMS"),
              arguments.indices.contains(index + 1),
              let value = Int(arguments[index + 1])
        else {
            return 650
        }

        return max(0, value)
    }
}

enum MockMarketplaceData {
    static let listings: [Listing] = [
        Listing(
            id: "1",
            category: .rehome,
            title: "Бадди ищет дом",
            animalType: .dog,
            breed: "Лабрадор-ретривер",
            age: "2 года",
            sex: .male,
            location: "Липецк, Хамовники",
            imageURL: url("https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?w=600&h=600&fit=crop&auto=format"),
            description: "Бадди - добрый и ласковый лабрадор, который очень любит людей. Уезжаем за границу, вынуждены найти ему новый дом. Привит, стерилизован, знает базовые команды.",
            authorName: "Анна М.",
            authorAvatarURL: url("https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&h=120&fit=crop&auto=format"),
            date: "Сегодня, 14:30",
            tags: ["Привит", "Стерилизован", "Знает команды"],
            isUrgent: true,
            pricePerDay: nil
        ),
        Listing(
            id: "2",
            category: .lost,
            title: "Потерялась Луна",
            animalType: .cat,
            breed: "Шотландская вислоухая",
            age: "3 года",
            sex: .female,
            location: "Липецк, Центр",
            imageURL: url("https://images.unsplash.com/photo-1607125836969-c887be445cc2?w=600&h=600&fit=crop&auto=format"),
            description: "Потерялась 20 мая около метро Василеостровская. Серая с белым, на ошейнике золотой медальон с именем. Очень боится посторонних, может прятаться.",
            authorName: "Дмитрий К.",
            authorAvatarURL: url("https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&h=120&fit=crop&auto=format"),
            date: "Сегодня, 09:15",
            tags: ["Вознаграждение", "Есть чип", "Серая"],
            isUrgent: true,
            pricePerDay: nil
        ),
        Listing(
            id: "3",
            category: .found,
            title: "Найден рыжий кот",
            animalType: .cat,
            breed: "Беспородный",
            age: "~2 года",
            sex: .male,
            location: "Липецк, Марьино",
            imageURL: url("https://images.unsplash.com/photo-1743835338821-4ca85d797ba4?w=600&h=600&fit=crop&auto=format"),
            description: "Нашли рыжего кота с голубыми глазами у дома 12 по ул. Люблинская. Ухоженный, не агрессивный, скорее всего домашний.",
            authorName: "Юлия П.",
            authorAvatarURL: url("https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=120&h=120&fit=crop&auto=format"),
            date: "Вчера, 18:00",
            tags: ["Ухоженный", "Дружелюбный", "Голубые глаза"],
            isUrgent: false,
            pricePerDay: nil
        ),
        Listing(
            id: "4",
            category: .boardingNeeded,
            title: "Нужна передержка для кошки",
            animalType: .cat,
            breed: "Британская короткошерстная",
            age: "4 года",
            sex: .female,
            location: "Липецк, Ниженка",
            imageURL: url("https://images.unsplash.com/photo-1533738363-b7f9aef128ce?w=600&h=600&fit=crop&auto=format"),
            description: "Уезжаю в командировку с 1 по 15 июня. Нужна передержка для тихой, воспитанной кошки. Все необходимое предоставлю.",
            authorName: "Мария С.",
            authorAvatarURL: url("https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=120&h=120&fit=crop&auto=format"),
            date: "3 дня назад",
            tags: ["1-15 июня", "Тихая", "Все включено"],
            isUrgent: false,
            pricePerDay: 500
        ),
        Listing(
            id: "5",
            category: .boardingOffer,
            title: "Приму кота или собаку",
            animalType: .dog,
            breed: "Любая порода",
            age: "Любой возраст",
            sex: .female,
            location: "Липецк, Сокол",
            imageURL: url("https://images.unsplash.com/photo-1529040274442-815019b0e4fc?w=600&h=600&fit=crop&auto=format"),
            description: "Опытный передержчик с большой квартирой и двором. Принимаю кошек и небольших собак. Ежедневные прогулки и видеоотчеты.",
            authorName: "Елена В.",
            authorAvatarURL: url("https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=120&h=120&fit=crop&auto=format"),
            date: "Сегодня, 11:00",
            tags: ["Опыт 5 лет", "Есть двор", "Видеоотчеты"],
            isUrgent: false,
            pricePerDay: 500
        ),
        Listing(
            id: "6",
            category: .rehome,
            title: "Отдам кролика Снежка",
            animalType: .rabbit,
            breed: "Карликовый кролик",
            age: "1,5 года",
            sex: .male,
            location: "Липецк, Тушино",
            imageURL: url("https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?w=600&h=600&fit=crop&auto=format"),
            description: "Снежок - ласковый белый кролик. Клетка, кормушка и запас корма идут в комплекте. Отдам только в добрые руки.",
            authorName: "Кирилл Р.",
            authorAvatarURL: url("https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120&h=120&fit=crop&auto=format"),
            date: "4 дня назад",
            tags: ["С клеткой", "Тихий", "Ручной"],
            isUrgent: false,
            pricePerDay: nil
        ),
        Listing(
            id: "7",
            category: .volunteer,
            title: "Волонтеры в приют",
            animalType: .other,
            breed: "Разные животные",
            age: "-",
            sex: .female,
            location: "Липецк, Люблино",
            imageURL: url("https://images.unsplash.com/photo-1594004844563-536a03a6e532?w=600&h=600&fit=crop&auto=format"),
            description: "Приют ищет волонтеров для выгула собак по выходным. Нужны ответственные люди от 18 лет. Обучим всему.",
            authorName: "Приют Лучший друг",
            authorAvatarURL: url("https://images.unsplash.com/photo-1675701917791-debd2d61cc4a?w=120&h=120&fit=crop&auto=format"),
            date: "Неделю назад",
            tags: ["По выходным", "Обучение", "Команда"],
            isUrgent: false,
            pricePerDay: nil
        ),
        Listing(
            id: "8",
            category: .lost,
            title: "Потерялась такса Бетти",
            animalType: .dog,
            breed: "Такса стандартная",
            age: "5 лет",
            sex: .female,
            location: "Липецк, Сокольники",
            imageURL: url("https://images.unsplash.com/photo-1510337550647-e84f83e341ca?w=600&h=600&fit=crop&auto=format"),
            description: "Потерялась 22 мая в Сокольническом парке. Рыжая такса, зеленый ошейник. Не агрессивная, на кличку Бетти откликается.",
            authorName: "Николай Ф.",
            authorAvatarURL: url("https://images.unsplash.com/photo-1463453091185-61582044d556?w=120&h=120&fit=crop&auto=format"),
            date: "Сегодня, 07:00",
            tags: ["Вознаграждение 30k", "Зеленый ошейник", "Рыжая"],
            isUrgent: true,
            pricePerDay: nil
        )
    ]

    static let myListings: [Listing] = [
        Listing(
            id: "mine-pending",
            ownerID: "mock-user",
            category: .rehome,
            status: .pending,
            title: "Мурка ищет дом",
            animalType: .cat,
            breed: "Беспородная",
            age: "8 месяцев",
            sex: .female,
            location: "Липецк, Центр",
            imageURL: url("https://images.unsplash.com/photo-1574158622682-e40e69881006?w=600&h=600&fit=crop&auto=format"),
            description: "Ласковая кошка, приучена к лотку. Публикация ожидает проверки модератором.",
            authorName: profile.name,
            authorAvatarURL: profile.avatarURL,
            date: "Сегодня, 12:10",
            tags: ["Лоток", "Ласковая"],
            isUrgent: false,
            pricePerDay: nil
        ),
        Listing(
            id: "mine-active",
            ownerID: "mock-user",
            category: .boardingOffer,
            status: .active,
            title: "Передержка для кошек",
            animalType: .cat,
            breed: "Любая",
            age: "Любой возраст",
            sex: .female,
            location: "Липецк, Сокол",
            imageURL: url("https://images.unsplash.com/photo-1518791841217-8f162f1e1131?w=600&h=600&fit=crop&auto=format"),
            description: "Принимаю спокойных кошек на короткую передержку.",
            authorName: profile.name,
            authorAvatarURL: profile.avatarURL,
            date: "Вчера, 17:30",
            tags: ["Передержка", "Фотоотчеты"],
            isUrgent: false,
            pricePerDay: 700
        ),
        Listing(
            id: "mine-rejected",
            ownerID: "mock-user",
            category: .lost,
            status: .rejected,
            title: "Потерялся попугай",
            animalType: .bird,
            breed: "Волнистый",
            age: "1 год",
            sex: .male,
            location: "Липецк, Сырский",
            imageURL: nil,
            description: "Нужно добавить фото и точное место, чтобы публикация прошла модерацию.",
            authorName: profile.name,
            authorAvatarURL: profile.avatarURL,
            date: "2 дня назад",
            tags: ["Нужно исправить"],
            isUrgent: true,
            pricePerDay: nil
        ),
        Listing(
            id: "mine-closed",
            ownerID: "mock-user",
            category: .found,
            status: .closed,
            title: "Хозяин найден",
            animalType: .dog,
            breed: "Метис",
            age: "3 года",
            sex: .male,
            location: "Липецк, Университетский",
            imageURL: nil,
            description: "Публикация закрыта владельцем.",
            authorName: profile.name,
            authorAvatarURL: profile.avatarURL,
            date: "Неделю назад",
            tags: ["Закрыто"],
            isUrgent: false,
            pricePerDay: nil
        )
    ]

    static let shelters: [Shelter] = [
        Shelter(
            id: "s1",
            name: "Лучший друг",
            city: "Липецк, Люблино",
            imageURL: url("https://images.unsplash.com/photo-1675701917791-debd2d61cc4a?w=800&h=400&fit=crop&auto=format"),
            animals: 127,
            description: "Один из старейших липецких приютов. Более 2000 животных нашли дом за все время работы.",
            phone: "+7 (4742) 123-45-67",
            urgentCount: 12
        ),
        Shelter(
            id: "s2",
            name: "Кот и пес",
            city: "Липецк, Солнцево",
            imageURL: url("https://images.unsplash.com/photo-1600020389909-2bda4d1862cd?w=800&h=400&fit=crop&auto=format"),
            animals: 89,
            description: "Частный приют для кошек и собак. Очень нужна помощь с кормом и медикаментами.",
            phone: "+7 (4742) 987-65-43",
            urgentCount: 7
        ),
        Shelter(
            id: "s3",
            name: "Добрые лапы",
            city: "Липецк, Сселки",
            imageURL: url("https://images.unsplash.com/photo-1594004844563-536a03a6e532?w=800&h=400&fit=crop&auto=format"),
            animals: 204,
            description: "Крупнейший приют Липецкой области. Срочно ищем передержки и волонтеров.",
            phone: "+7 (4742) 555-00-11",
            urgentCount: 23
        )
    ]

    static let petSitters: [PetSitter] = [
        PetSitter(
            id: "ps1",
            name: "Елена Васильева",
            avatarURL: url("https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=160&h=160&fit=crop&auto=format"),
            rating: 4.9,
            reviews: 84,
            pricePerDay: 700,
            location: "Липецк, Сокол",
            services: ["Передержка у меня", "Выгул", "Посещения на дому"],
            bio: "Ветеринарный техник. 7 лет опыта. Люблю всех животных, особенно немолодых и особенных.",
            animalTypes: [.dog, .cat]
        ),
        PetSitter(
            id: "ps2",
            name: "Иван Андреев",
            avatarURL: url("https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=160&h=160&fit=crop&auto=format"),
            rating: 4.7,
            reviews: 41,
            pricePerDay: 600,
            location: "Липецк, Арбат",
            services: ["Передержка у меня", "Посещения на дому"],
            bio: "Работаю удаленно, почти всегда дома. Тихая квартира с балконом.",
            animalTypes: [.cat, .rabbit, .hamster]
        ),
        PetSitter(
            id: "ps3",
            name: "Мария Соколова",
            avatarURL: url("https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=160&h=160&fit=crop&auto=format"),
            rating: 5.0,
            reviews: 23,
            pricePerDay: 900,
            location: "Липецк, Патрики",
            services: ["Овернайт у клиента", "Выгул", "Груминг"],
            bio: "Профессиональный грумер и хендлер. Специализируюсь на крупных породах.",
            animalTypes: [.dog]
        )
    ]

    static let conversations: [Conversation] = [
        Conversation(
            id: "c1",
            name: "Анна М.",
            avatarURL: url("https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&h=120&fit=crop&auto=format"),
            lastMessage: "Да, можно приехать посмотреть в субботу",
            time: "14:35",
            unreadCount: 2,
            listingTitle: "Бадди ищет дом",
            otherParticipantID: "mock-user-anna",
            messages: [
                ChatMessage(id: "m1", senderID: "tester@example.com", text: "Здравствуйте! Увидела объявление о Бадди.", sender: .me, time: "13:10"),
                ChatMessage(id: "m2", senderID: "mock-user-anna", text: "Здравствуйте! Бадди замечательный пес.", sender: .them, time: "13:25"),
                ChatMessage(id: "m3", senderID: "tester@example.com", text: "Можно ли приехать посмотреть?", sender: .me, time: "14:20"),
                ChatMessage(id: "m4", senderID: "mock-user-anna", text: "Да, можно приехать посмотреть в субботу", sender: .them, time: "14:35")
            ]
        ),
        Conversation(
            id: "c2",
            name: "Дмитрий К.",
            avatarURL: url("https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&h=120&fit=crop&auto=format"),
            lastMessage: "Спасибо, сообщу если что-то узнаем",
            time: "Вчера",
            unreadCount: 0,
            listingTitle: "Потерялась Луна",
            otherParticipantID: "mock-user-dmitry",
            messages: [
                ChatMessage(id: "m5", senderID: "tester@example.com", text: "Видел серую кошку около Гавани.", sender: .me, time: "Вчера, 11:00"),
                ChatMessage(id: "m6", senderID: "mock-user-dmitry", text: "Спасибо! Можете прислать фото?", sender: .them, time: "Вчера, 11:15")
            ]
        )
    ]

    static let reports: [ReportResponse] = [
        ReportResponse(
            id: "report-open",
            targetType: .listing,
            targetID: "2",
            reason: ReportReason.fraud.title,
            details: "Пользователь просит перевести деньги вне Fluffy.",
            status: .reviewing,
            createdAt: Date().addingTimeInterval(-86_400),
            updatedAt: Date().addingTimeInterval(-3_600)
        ),
        ReportResponse(
            id: "report-resolved",
            targetType: .listing,
            targetID: "7",
            reason: ReportReason.wrongCategory.title,
            details: nil,
            status: .resolved,
            createdAt: Date().addingTimeInterval(-172_800),
            updatedAt: Date().addingTimeInterval(-120_000)
        )
    ]

    static let notificationPreferences = NotificationPreferences(
        replies: true,
        moderation: true,
        safety: true,
        updatedAt: Date().addingTimeInterval(-3_600)
    )

    static let profile = UserProfile(
        name: "Мария Соколова",
        handle: "@msokolova",
        city: "Липецк",
        email: "maria@example.com",
        phone: "+7 900 123-45-67",
        avatarURL: url("https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=160&h=160&fit=crop&auto=format"),
        verificationStatus: .notStarted,
        rating: 4.9,
        reviews: 12,
        listingsCount: 2,
        dealsCount: 7,
        daysOnPlatform: 341
    )

    private static func url(_ value: String) -> URL? {
        URL(string: value)
    }
}
