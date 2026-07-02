//
//  ProfileCompletionViewModel.swift
//  Fluffy
//

import Foundation
import Observation
import UIKit

protocol ProfileCompletionCoordinating: AnyObject {
    func profileCompletionDidFinish(session: AuthSession)
    func cancelProfileCompletion()
}

@Observable
final class ProfileCompletionViewModel {
    var name = ""
    var cities: [City] = CityCatalog.fallback
    var selectedCity: City = CityCatalog.defaultCity
    var phone = ""
    var avatarImage: UIImage?
    var avatarData: Data?
    var isSaving = false
    var errorMessage: String?

    let country = "Россия"

    private var session: AuthSession
    private weak var coordinator: ProfileCompletionCoordinating?
    private let marketplaceService: MarketplaceServicing
    private let mediaService: MediaServicing
    private let cityService: CityServicing

    init(
        session: AuthSession,
        coordinator: ProfileCompletionCoordinating?,
        marketplaceService: MarketplaceServicing,
        mediaService: MediaServicing,
        cityService: CityServicing
    ) {
        self.session = session
        self.coordinator = coordinator
        self.marketplaceService = marketplaceService
        self.mediaService = mediaService
        self.cityService = cityService
    }

    var email: String {
        session.user.email
    }

    var isSaveEnabled: Bool {
        !trimmed(name).isEmpty
            && normalizedRussianPhone != nil
            && !isSaving
    }

    func loadCities() async {
        guard let fetched = try? await cityService.fetchCities(), !fetched.isEmpty else { return }
        cities = fetched
        if !fetched.contains(where: { $0.slug == selectedCity.slug }) {
            selectedCity = fetched[0]
        }
    }

    var phoneValidationMessage: String? {
        guard !trimmed(phone).isEmpty, normalizedRussianPhone == nil else { return nil }
        return String(localized: "profile_completion_phone_error")
    }

    func setAvatar(_ image: UIImage?) {
        avatarImage = image
        avatarData = image?.jpegData(compressionQuality: 0.82)
    }

    func saveTapped() {
        guard isSaveEnabled else { return }

        Task {
            await save()
        }
    }

    func signOutTapped() {
        coordinator?.cancelProfileCompletion()
    }

    private func save() async {
        isSaving = true
        errorMessage = nil

        do {
            let uploadedAvatarURL: URL?
            if let avatarData {
                uploadedAvatarURL = try await mediaService.uploadProfileAvatar(
                    data: avatarData,
                    fileName: "profile-avatar.jpg",
                    mimeType: "image/jpeg"
                )
            } else {
                uploadedAvatarURL = nil
            }

            let draft = UserProfileDraft(
                name: trimmed(name),
                handle: "",
                city: selectedCity.name,
                citySlug: selectedCity.slug,
                phone: normalizedRussianPhone ?? trimmed(phone),
                avatarURL: uploadedAvatarURL
            )
            _ = try await marketplaceService.updateUserProfile(draft)

            var completedSession = session
            completedSession.requiresProfileCompletion = false
            isSaving = false
            coordinator?.profileCompletionDidFinish(session: completedSession)
        } catch {
            isSaving = false
            errorMessage = String(localized: "profile_completion_save_error")
        }
    }

    private var normalizedRussianPhone: String? {
        let digits = phone.filter(\.isNumber)
        if digits.count == 10 {
            return "+7\(digits)"
        }
        if digits.count == 11, let first = digits.first, first == "7" || first == "8" {
            return "+7\(digits.dropFirst())"
        }
        return nil
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
