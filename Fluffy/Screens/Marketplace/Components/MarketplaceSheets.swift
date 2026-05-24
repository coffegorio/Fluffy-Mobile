//
//  MarketplaceSheets.swift
//  Fluffy
//

import SwiftUI

struct AddListingSheet: View {
    let isSaving: Bool
    let onSubmit: (ListingDraft) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ListingDraft()
    @State private var priceText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("listing_form_main_section") {
                    TextField("listing_form_title", text: $draft.title)
                    TextField("listing_form_breed", text: $draft.breed)
                    TextField("listing_form_age", text: $draft.age)
                    TextField("listing_form_location", text: $draft.location)
                }

                Section("listing_form_type_section") {
                    Picker("listing_form_category", selection: $draft.category) {
                        ForEach(ListingCategory.allCases.filter { $0 != .all }) { category in
                            Text(category.titleKey).tag(category)
                        }
                    }

                    Picker("listing_form_animal", selection: $draft.animalType) {
                        ForEach(AnimalType.allCases) { animal in
                            Label(animal.rawValue.capitalized, systemImage: animal.systemImage).tag(animal)
                        }
                    }

                    Picker("detail_sex", selection: $draft.sex) {
                        ForEach(PetSex.allCases) { sex in
                            Text(sex.titleKey).tag(sex)
                        }
                    }

                    Toggle("listing_form_urgent", isOn: $draft.isUrgent)
                }

                Section("detail_description") {
                    TextField("listing_form_description", text: $draft.description, axis: .vertical)
                        .lineLimit(4...8)
                    TextField("listing_form_price", text: $priceText)
                        .keyboardType(.numberPad)
                        .onChange(of: priceText) { _, newValue in
                            draft.pricePerDay = Int(newValue.filter(\.isNumber))
                        }
                }
            }
            .navigationTitle("add_listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common_cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await onSubmit(draft)
                            dismiss()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("common_create")
                        }
                    }
                    .disabled(!draft.isValid || isSaving)
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct ProfileCompletionSheet: View {
    let profile: UserProfile?
    let isSaving: Bool
    let onSubmit: (UserProfileDraft) async -> Void

    @State private var draft: UserProfileDraft

    init(
        profile: UserProfile?,
        isSaving: Bool,
        onSubmit: @escaping (UserProfileDraft) async -> Void
    ) {
        self.profile = profile
        self.isSaving = isSaving
        self.onSubmit = onSubmit
        _draft = State(
            initialValue: profile?.draft ?? UserProfileDraft(name: "", handle: "", city: "", phone: "")
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("profile_completion_subtitle")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Section("profile_completion_section") {
                    TextField("profile_form_name", text: $draft.name)
                    TextField("profile_form_handle", text: $draft.handle)
                        .textInputAutocapitalization(.never)
                    TextField("profile_form_city", text: $draft.city)
                    TextField("profile_form_phone", text: $draft.phone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("profile_completion_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await onSubmit(draft)
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("common_save")
                        }
                    }
                    .disabled(!draft.isValid || isSaving)
                }
            }
        }
        .interactiveDismissDisabled()
        .presentationDetents([.medium, .large])
    }
}

struct MarketplaceStatusSheet: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(AppTheme.accent)

            Text(title)
                .font(.system(size: 22, weight: .heavy))
                .multilineTextAlignment(.center)

            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("common_done")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .presentationDetents([.height(300)])
    }
}

struct ProfileActionSheet: View {
    let action: ProfileMenuAction
    let onSignOut: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(AppTheme.accent)

            Text(titleKey)
                .font(.system(size: 22, weight: .heavy))

            Text(messageKey)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)

            if action == .security {
                Button(role: .destructive) {
                    dismiss()
                    onSignOut()
                } label: {
                    Text("profile_sign_out")
                        .font(.system(size: 16, weight: .heavy))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            Button {
                dismiss()
            } label: {
                Text("common_done")
                    .font(.system(size: 16, weight: .heavy))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .presentationDetents([.height(action == .security ? 360 : 300)])
    }

    private var iconName: String {
        switch action {
        case .listings: "list.bullet.rectangle"
        case .notifications: "bell"
        case .security: "lock.shield"
        case .help: "bubble.left.and.bubble.right"
        case .about: "info.circle"
        }
    }

    private var titleKey: LocalizedStringKey {
        switch action {
        case .listings: "profile_menu_listings"
        case .notifications: "profile_menu_notifications"
        case .security: "profile_menu_security"
        case .help: "profile_menu_help"
        case .about: "profile_menu_about"
        }
    }

    private var messageKey: LocalizedStringKey {
        switch action {
        case .listings: "profile_action_listings_message"
        case .notifications: "profile_action_notifications_message"
        case .security: "profile_action_security_message"
        case .help: "profile_action_help_message"
        case .about: "profile_action_about_message"
        }
    }
}
