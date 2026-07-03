//
//  ProfileCompletionView.swift
//  Fluffy
//

import Observation
import PhotosUI
import SwiftUI
import UIKit

struct ProfileCompletionView: View {
    @State var viewModel: ProfileCompletionViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @FocusState private var focusedField: ProfileCompletionFocusedField?

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            ProfileCompletionPalette.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 24) {
                        ProfileCompletionHeader()

                        ProfileCompletionAvatarSection(
                            avatarImage: viewModel.avatarImage,
                            selectedPhotoItem: $selectedPhotoItem
                        )

                        ProfileCompletionFormSection(
                            name: $viewModel.name,
                            country: viewModel.country,
                            cities: viewModel.cities,
                            selectedCity: $viewModel.selectedCity,
                            phone: $viewModel.phone,
                            phoneValidationMessage: viewModel.phoneValidationMessage,
                            focusedField: $focusedField
                        )

                        ProfileCompletionInfoCard()

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, ProfileCompletionLayout.horizontalPadding)
                    .padding(.top, ProfileCompletionLayout.topPadding)
                    .padding(.bottom, ProfileCompletionLayout.scrollBottomPadding)

                    ProfileCompletionFooter(
                        isSaveEnabled: viewModel.isSaveEnabled,
                        isSaving: viewModel.isSaving,
                        onSave: viewModel.saveTapped,
                        onSignOut: viewModel.signOutTapped
                    )
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: dismissKeyboard)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarBackButtonHidden()
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                await loadPhoto(item)
            }
        }
        .task {
            await viewModel.loadCities()
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else {
            return
        }
        viewModel.setAvatar(image)
    }

    private func dismissKeyboard() {
        focusedField = nil
    }
}

private struct ProfileCompletionHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.accent)

                Image(systemName: "pawprint.fill")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)
            }
            .frame(width: 52, height: 52)
            .shadow(color: AppTheme.accent.opacity(0.24), radius: 16, x: 0, y: 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Добро пожаловать в Fluffy!")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Расскажите немного о себе, чтобы другие пользователи могли вас узнать")
                    .font(.system(size: 15, weight: .regular))
                    .lineSpacing(3)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ProfileCompletionAvatarSection: View {
    let avatarImage: UIImage?
    @Binding var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProfileCompletionLabel(text: "Фото профиля", isRequired: false)

            HStack(spacing: 16) {
                avatarPreview

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .bold))

                        Text("Загрузить фото")
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 16)
                    .frame(height: 46)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("profile_completion_avatar_picker")

                Spacer(minLength: 0)
            }
        }
    }

    private var avatarPreview: some View {
        ZStack {
            Circle()
                .fill(AppTheme.muted)

            if let avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(width: 82, height: 82)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 4))
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
    }
}

private struct ProfileCompletionFormSection: View {
    @Binding var name: String
    let country: String
    let cities: [City]
    @Binding var selectedCity: City
    @Binding var phone: String
    let phoneValidationMessage: String?
    var focusedField: FocusState<ProfileCompletionFocusedField?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Основная информация")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(AppTheme.text)

            ProfileCompletionTextField(
                label: "Ваше имя",
                placeholder: "Например, Мария",
                icon: "person",
                isRequired: true,
                textInputAutocapitalization: .words,
                accessibilityIdentifier: "profile_completion_name_field",
                text: $name
            )
            .focused(focusedField, equals: .name)

            ProfileCompletionReadonlyRow(
                label: "Страна",
                value: country,
                icon: "mappin.and.ellipse",
                badge: "Выбрано"
            )

            ProfileCompletionCityPicker(
                cities: cities,
                selectedCity: $selectedCity
            )

            ProfileCompletionRussianPhoneField(phone: $phone)
                .focused(focusedField, equals: .phone)

            if let phoneValidationMessage {
                Text(phoneValidationMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.danger)
                    .padding(.top, -6)
            }
        }
    }
}

private struct ProfileCompletionRussianPhoneField: View {
    @Binding var phone: String

    private var nationalDigits: String {
        var digits = phone.filter(\.isNumber)
        if digits.first == "7" || digits.first == "8" {
            digits.removeFirst()
        }
        return String(digits.prefix(10))
    }

    private var formattedNationalDigits: String {
        let digits = nationalDigits
        guard !digits.isEmpty else { return "" }
        var result = String(digits.prefix(3))
        if digits.count > 3 { result += " \(digits.dropFirst(3).prefix(3))" }
        if digits.count > 6 { result += "-\(digits.dropFirst(6).prefix(2))" }
        if digits.count > 8 { result += "-\(digits.dropFirst(8).prefix(2))" }
        return result
    }

    private var nationalDigitsBinding: Binding<String> {
        Binding(
            get: { formattedNationalDigits },
            set: { newValue in
                let digits = String(newValue.filter(\.isNumber).prefix(10))
                phone = digits.isEmpty ? "" : "+7\(digits)"
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileCompletionLabel(text: "Телефон", isRequired: true)

            HStack(spacing: 10) {
                Text("+7")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)

                TextField("900 123-45-67", text: nationalDigitsBinding)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.text)
                    .keyboardType(.phonePad)
                    .accessibilityLabel("Телефон")
                    .accessibilityIdentifier("profile_completion_phone_field")

                Image(systemName: "phone")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.72))
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: ProfileCompletionLayout.controlRadius, style: .continuous))
            .shadow(color: .black.opacity(0.035), radius: 12, x: 0, y: 6)
        }
    }
}

private struct ProfileCompletionTextField: View {
    let label: String
    let placeholder: String
    let icon: String
    let isRequired: Bool
    var keyboardType: UIKeyboardType = .default
    var textInputAutocapitalization: TextInputAutocapitalization = .never
    var accessibilityIdentifier: String?

    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileCompletionLabel(text: label, isRequired: isRequired)

            HStack(spacing: 10) {
                TextField(placeholder, text: $text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(textInputAutocapitalization)
                    .autocorrectionDisabled()
                    .accessibilityLabel(label)
                    .accessibilityIdentifier(accessibilityIdentifier ?? label)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.72))
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: ProfileCompletionLayout.controlRadius, style: .continuous))
            .shadow(color: .black.opacity(0.035), radius: 12, x: 0, y: 6)
        }
    }
}

private struct ProfileCompletionCityPicker: View {
    let cities: [City]
    @Binding var selectedCity: City

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileCompletionLabel(text: "Город", isRequired: true)

            Menu {
                ForEach(cities) { city in
                    Button {
                        selectedCity = city
                    } label: {
                        if city.slug == selectedCity.slug {
                            Label(city.name, systemImage: "checkmark")
                        } else {
                            Text(city.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(selectedCity.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.text)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText.opacity(0.72))

                    Image(systemName: "mappin")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText.opacity(0.72))
                        .frame(width: 20, height: 20)
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: ProfileCompletionLayout.controlRadius, style: .continuous))
                .shadow(color: .black.opacity(0.035), radius: 12, x: 0, y: 6)
            }
            .accessibilityIdentifier("profile_completion_city_field")
        }
    }
}

private struct ProfileCompletionReadonlyRow: View {
    let label: String
    let value: String
    let icon: String
    let badge: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileCompletionLabel(text: label, isRequired: false)

            HStack(spacing: 10) {
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.text)

                Spacer()

                Text(badge)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.72))
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: ProfileCompletionLayout.controlRadius, style: .continuous))
            .shadow(color: .black.opacity(0.035), radius: 12, x: 0, y: 6)
        }
    }
}

private struct ProfileCompletionLabel: View {
    let text: String
    let isRequired: Bool

    var body: some View {
        HStack(spacing: 3) {
            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.text)

            if isRequired {
                Text("*")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }
}

private struct ProfileCompletionInfoCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(width: 34, height: 34)

            Text("Эти данные помогут другим пользователям узнать вас лучше. Вы всегда сможете изменить информацию в профиле.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.accent)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(AppTheme.accentSoft, in: RoundedRectangle(cornerRadius: ProfileCompletionLayout.cardRadius, style: .continuous))
    }
}

private struct ProfileCompletionFooter: View {
    let isSaveEnabled: Bool
    let isSaving: Bool
    let onSave: () -> Void
    let onSignOut: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onSave) {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Продолжить")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .heavy))
                    }
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(AppTheme.accent.opacity(isSaveEnabled ? 1 : 0.42), in: RoundedRectangle(cornerRadius: ProfileCompletionLayout.cardRadius, style: .continuous))
            }
            .disabled(!isSaveEnabled)
            .accessibilityIdentifier("profile_completion_save_button")

            Button(action: onSignOut) {
                Text("Выйти из аккаунта")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ProfileCompletionLayout.horizontalPadding)
        .padding(.top, 16)
        .padding(.bottom, ProfileCompletionLayout.footerBottomPadding)
    }
}

private enum ProfileCompletionLayout {
    static let horizontalPadding: CGFloat = 24
    static let topPadding: CGFloat = 52
    static let scrollBottomPadding: CGFloat = 20
    static let footerBottomPadding: CGFloat = 28
    static let controlRadius: CGFloat = 18
    static let cardRadius: CGFloat = 20
}

private enum ProfileCompletionPalette {
    static let background = Color(red: 0.97, green: 0.97, blue: 0.96)
}

private enum ProfileCompletionFocusedField: Hashable {
    case name
    case phone
}

#Preview {
    ProfileCompletionView(
        viewModel: ProfileCompletionViewModel(
            session: AuthSession(
                accessToken: "preview",
                refreshToken: "preview",
                expiresAt: Date().addingTimeInterval(900),
                user: AuthUser(id: "preview", email: "preview@fluffy.local"),
                role: .user,
                verificationStatus: .notStarted,
                requiresProfileCompletion: true
            ),
            coordinator: nil,
            marketplaceService: MockMarketplaceService(),
            mediaService: MockMediaService(),
            cityService: MockCityService()
        )
    )
}
