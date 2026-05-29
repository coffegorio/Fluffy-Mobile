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

        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.white
                    .ignoresSafeArea()

                topBackground

                ScrollView {
                    ZStack(alignment: .top) {
                        AuthWaveShape()
                            .fill(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: ProfileCompletionLayout.panelHeight(for: proxy.size.height))
                            .padding(.top, ProfileCompletionLayout.panelTop)

                        VStack(alignment: .leading, spacing: 16) {
                            header
                            avatarPicker
                            form
                            footer
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, ProfileCompletionLayout.contentTop)
                        .padding(.bottom, 30)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: ProfileCompletionLayout.scrollContentHeight(for: proxy.size.height), alignment: .top)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("common_done", action: dismissKeyboard)
                    .accessibilityIdentifier("profile_completion_keyboard_done")
            }
        }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                await loadPhoto(item)
            }
        }
    }

    private var topBackground: some View {
        Image(decorative: "WelcomeBackground")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: ProfileCompletionLayout.backgroundHeight)
            .clipped()
            .ignoresSafeArea(.container, edges: .top)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("profile_completion_title")
                .font(.system(size: 29, weight: .heavy))
                .foregroundStyle(AppTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text("profile_completion_subtitle")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var avatarPicker: some View {
        HStack(spacing: 14) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let avatarImage = viewModel.avatarImage {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 58, weight: .semibold))
                                .foregroundStyle(AppTheme.accent.opacity(0.84))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(AppTheme.accentSoft)
                        }
                    }
                    .frame(width: 86, height: 86)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.92), lineWidth: 3))
                    .shadow(color: AppTheme.accent.opacity(0.18), radius: 14, y: 8)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(AppTheme.accent, in: Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("profile_completion_avatar_picker")

            VStack(alignment: .leading, spacing: 6) {
                Text("profile_completion_photo_title")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                Text("profile_completion_photo_subtitle")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(AppTheme.accentSoft.opacity(0.46), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(.white.opacity(0.82), lineWidth: 1)
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("profile_completion_section")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(AppTheme.text)

            LabeledTextField(
                label: String(localized: "profile_form_name"),
                placeholder: String(localized: "profile_completion_name_placeholder"),
                icon: "person",
                textInputAutocapitalization: .words,
                accessibilityIdentifier: "profile_completion_name_field",
                text: $viewModel.name
            )
            .focused($focusedField, equals: .name)

            ProfileCompletionReadonlyField(
                label: String(localized: "profile_completion_country"),
                value: viewModel.country,
                icon: "mappin.and.ellipse"
            )

            LabeledTextField(
                label: String(localized: "profile_form_city"),
                placeholder: String(localized: "profile_completion_city_placeholder"),
                icon: "building.2",
                textInputAutocapitalization: .words,
                accessibilityIdentifier: "profile_completion_city_field",
                text: $viewModel.city
            )
            .focused($focusedField, equals: .city)

            LabeledTextField(
                label: String(localized: "profile_form_phone"),
                placeholder: "+7 900 123-45-67",
                icon: "phone",
                keyboardType: .phonePad,
                accessibilityIdentifier: "profile_completion_phone_field",
                text: $viewModel.phone
            )
            .focused($focusedField, equals: .phone)

            if let phoneValidationMessage = viewModel.phoneValidationMessage {
                Text(phoneValidationMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.danger)
            }
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.46), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(.black.opacity(0.04), lineWidth: 1)
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                viewModel.saveTapped()
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }

                    Text("profile_completion_save_button")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppTheme.accent.opacity(viewModel.isSaveEnabled ? 0.94 : 0.46), in: Capsule())
                .fluffyProminentGlass(cornerRadius: 28, tint: AppTheme.accent.opacity(0.34))
            }
            .disabled(!viewModel.isSaveEnabled)
            .accessibilityIdentifier("profile_completion_save_button")

            Button {
                viewModel.signOutTapped()
            } label: {
                Text("profile_completion_sign_out")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
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
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

private enum ProfileCompletionLayout {
    static let backgroundHeight: CGFloat = 318
    static let panelTop: CGFloat = 108
    static let contentTop: CGFloat = 295

    static func panelHeight(for screenHeight: CGFloat) -> CGFloat {
        max(screenHeight + 210, 1_050)
    }

    static func scrollContentHeight(for screenHeight: CGFloat) -> CGFloat {
        panelTop + panelHeight(for: screenHeight)
    }
}

private enum ProfileCompletionFocusedField: Hashable {
    case name
    case city
    case phone
}

private struct ProfileCompletionReadonlyField: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)

                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.text)

                Spacer()

                Text("profile_completion_country_locked")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Color(.systemGray6).opacity(0.62))
            .fluffyGlass(cornerRadius: 12, tint: .white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
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
            mediaService: MockMediaService()
        )
    )
}
