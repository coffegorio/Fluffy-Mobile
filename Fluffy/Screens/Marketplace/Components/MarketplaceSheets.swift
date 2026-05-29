//
//  MarketplaceSheets.swift
//  Fluffy
//

import PhotosUI
import SwiftUI
import UIKit

struct AddListingSheet: View {
    private enum Step: Int, CaseIterable {
        case scenario
        case mainInfo
        case details
        case review

        var title: String {
            switch self {
            case .scenario: "Что разместить"
            case .mainInfo: "Основное"
            case .details: "Детали"
            case .review: "Проверка"
            }
        }
    }

    let isSaving: Bool
    let onSubmit: (ListingDraft) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var step: Step = .scenario
    @State private var draft = ListingDraft()
    @State private var priceText = ""
    @State private var rewardText = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        stepContent
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 108)
                }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .onTapGesture(perform: dismissKeyboard)

                bottomBar
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Добавить публикацию")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common_cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .onChange(of: selectedPhotoItem) { _, item in
            Task { await loadPhoto(item) }
        }
        .onChange(of: draft.publicationType) { _, type in
            applyDefaults(for: type)
        }
        .onChange(of: draft.publicationFormat) { _, format in
            if format == .nonCommercial {
                draft.pricePerDay = nil
                priceText = ""
                draft.pricingMode = .free
            } else if draft.pricingMode == .free {
                draft.pricingMode = .fixed
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ForEach(Step.allCases, id: \.self) { item in
                    Capsule()
                        .fill(item.rawValue <= step.rawValue ? AppTheme.accent : AppTheme.muted)
                        .frame(height: 5)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                Text("Показываем только поля, которые нужны для выбранного сценария.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .background(.white)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .scenario:
            scenarioStep
        case .mainInfo:
            mainInfoStep
        case .details:
            detailsStep
        case .review:
            reviewStep
        }
    }

    private var scenarioStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("Тип публикации")

            VStack(spacing: 12) {
                ForEach(PublicationType.allCases) { type in
                    ScenarioCard(
                        title: type.title,
                        subtitle: type.subtitle,
                        icon: type.icon,
                        isSelected: draft.publicationType == type
                    ) {
                        draft.publicationType = type
                    }
                }
            }

            sectionTitle("Формат")
            Picker("Формат", selection: $draft.publicationFormat) {
                ForEach(PublicationFormat.allCases) { format in
                    Text(format.title).tag(format)
                }
            }
            .pickerStyle(.segmented)

            Toggle(isOn: Binding(
                get: { draft.urgencyLevel == .urgent },
                set: { value in
                    draft.urgencyLevel = value ? .urgent : .normal
                    draft.isUrgent = value
                }
            )) {
                Label("Срочно", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
            }
            .tint(AppTheme.accent)
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var mainInfoStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionCard(title: "О публикации") {
                photoPicker
                field("Заголовок", text: $draft.title, placeholder: "Например: Срочно нужна помощь коту после операции")
                textEditor("Описание", text: $draft.description, placeholder: "Расскажите важные детали")
            }

            sectionCard(title: "О питомце") {
                Picker("Вид животного", selection: $draft.animalType) {
                    ForEach(AnimalType.allCases) { animal in
                        Label(animal.rawValue.capitalized, systemImage: animal.systemImage).tag(animal)
                    }
                }
                .pickerStyle(.menu)

                field("Имя питомца", text: $draft.petName, placeholder: "Если есть")
                field("Порода", text: $draft.breed, placeholder: "Можно указать метис")
                field("Возраст", text: $draft.age, placeholder: "Например: 2 года")

                Picker("Пол", selection: $draft.sex) {
                    ForEach(PetSex.allCases) { sex in
                        Text(sex.titleKey).tag(sex)
                    }
                }
                .pickerStyle(.segmented)
            }

            sectionCard(title: "Локация и связь") {
                field("Город", text: $draft.city, placeholder: "Липецк")
                field("Район", text: $draft.district, placeholder: "Опционально")
                field("Адрес / место", text: $draft.location, placeholder: "Улица, ориентир или район")

                Picker("Способ связи", selection: $draft.contactMethod) {
                    ForEach(ContactMethod.allCases) { method in
                        Text(method.title).tag(method)
                    }
                }
                .pickerStyle(.segmented)

                if draft.contactMethod != .chat {
                    field("Контакты", text: $draft.contactDetails, placeholder: "+7 или удобный способ связи")
                }
            }
        }
    }

    @ViewBuilder
    private var detailsStep: some View {
        switch draft.publicationType {
        case .urgentHelp:
            urgentHelpDetails
        case .listing:
            listingDetails
        case .adoption:
            adoptionDetails
        case .lostFound:
            lostFoundDetails
        case .petSitting:
            petSittingDetails
        }
    }

    private var urgentHelpDetails: some View {
        sectionCard(title: "Срочная помощь") {
            chipCloud(title: "Вид помощи", values: HelpKind.allCases, selection: $draft.helpKinds)

            Picker("Насколько срочно", selection: $draft.helpUrgency) {
                ForEach(HelpUrgency.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)

            field("Сумма сбора", text: $rewardText, placeholder: "Например: 12000", keyboard: .numberPad)
                .onChange(of: rewardText) { _, value in
                    draft.reward = Int(value.filter(\.isNumber))
                }
            field("Цель сбора", text: $draft.fundraisingGoal, placeholder: "Лекарства, операция, корм")
            textEditor("Документы / справки", text: $draft.documentsNote, placeholder: "Что сможете приложить или показать")
            Toggle("Метка Тревога", isOn: $draft.alarmEnabled)
                .tint(AppTheme.accent)
        }
    }

    private var listingDetails: some View {
        sectionCard(title: "Обычное объявление") {
            singleChoiceCloud(title: "Подтип", values: ListingSubtype.allCases, selection: $draft.listingSubtype)
            pricingBlock

            if draft.publicationFormat == .commercial {
                textEditor("Условия продажи", text: $draft.saleTerms, placeholder: "Оплата, бронь, возврат")
                field("Доставка / самовывоз", text: $draft.deliveryOptions, placeholder: "Самовывоз, доставка по городу")
            }
        }
    }

    private var adoptionDetails: some View {
        sectionCard(title: "Пристройство") {
            textEditor("Причина пристройства", text: $draft.adoptionReason, placeholder: "Почему питомцу ищут дом")
            textEditor("Условия передачи", text: $draft.transferTerms, placeholder: "Какие условия важны будущему хозяину")
            singleChoiceCloud(title: "Можно в семью с детьми", values: BooleanChoice.allCases, selection: $draft.familyWithKids)
            singleChoiceCloud(title: "Можно с другими животными", values: BooleanChoice.allCases, selection: $draft.otherPets)
            singleChoiceCloud(title: "Куда подойдет", values: HomePreference.allCases, selection: $draft.homePreference)
            Toggle("Стерилизован", isOn: $draft.isSterilized).tint(AppTheme.accent)
            Toggle("Вакцинирован", isOn: $draft.isVaccinated).tint(AppTheme.accent)
            Toggle("Нужно собеседование / договор", isOn: $draft.requiresInterview).tint(AppTheme.accent)
        }
    }

    private var lostFoundDetails: some View {
        sectionCard(title: "Потерялся / найден") {
            Picker("Статус", selection: $draft.lostFoundMode) {
                ForEach(LostFoundMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            DatePicker("Дата", selection: $draft.eventDate, displayedComponents: .date)
            field("Место", text: $draft.eventPlace, placeholder: "Где потерялся или найден")
            textEditor("Приметы", text: $draft.distinctiveFeatures, placeholder: "Окрас, ошейник, поведение, особые отметины")
            Toggle("Был ошейник / чип", isOn: $draft.hasCollarOrChip).tint(AppTheme.accent)
            Toggle("Нужна срочная помощь", isOn: $draft.needsUrgentCare).tint(AppTheme.accent)
        }
    }

    private var petSittingDetails: some View {
        sectionCard(title: "Передержка / pet-sitting") {
            Picker("Формат", selection: $draft.sittingMode) {
                ForEach(SittingMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            field("Даты", text: $draft.dates, placeholder: "Например: 12-18 июня")
            field("Длительность", text: $draft.duration, placeholder: "Несколько часов, 7 дней")
            textEditor("Условия", text: $draft.conditions, placeholder: "Что нужно или что вы предлагаете")
            if draft.publicationFormat == .commercial {
                pricingBlock
            }
            textEditor("Особенности питомца", text: $draft.petSpecialNeeds, placeholder: "Лекарства, режим, страхи, аллергии")
        }
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionCard(title: "Проверьте публикацию") {
                reviewRow("Тип", draft.publicationType.title)
                reviewRow("Формат", draft.publicationFormat.title)
                reviewRow("Срочность", draft.urgencyLevel.title)
                reviewRow("Заголовок", draft.title)
                reviewRow("Локация", draft.normalizedLocation)
                if let price = draft.pricePerDay, draft.publicationFormat == .commercial {
                    reviewRow("Цена", "\(price) ₽")
                }
                if let reward = draft.reward {
                    reviewRow("Сбор", "\(reward) ₽")
                }
                reviewRow("Теги", draft.tags.joined(separator: ", "))
            }

            sectionCard(title: "Описание для модерации") {
                Text(draft.submissionDescription)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(3)
            }
        }
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.accentSoft)

                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .frame(width: 76, height: 76)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(previewImage == nil ? "Добавить фото" : "Фото выбрано")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                    Text("Фото поможет быстрее пройти модерацию и получить отклик.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(14)
            .background(AppTheme.accentSoft.opacity(0.55), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var pricingBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            singleChoiceCloud(title: "Цена", values: PricingMode.allCases, selection: $draft.pricingMode)
                .onChange(of: draft.pricingMode) { _, mode in
                    if mode != .fixed {
                        priceText = ""
                        draft.pricePerDay = nil
                    }
                }

            if draft.publicationFormat == .commercial, draft.pricingMode == .fixed {
                field("Цена", text: $priceText, placeholder: "Например: 1500", keyboard: .numberPad)
                    .onChange(of: priceText) { _, value in
                        draft.pricePerDay = Int(value.filter(\.isNumber))
                    }
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step != .scenario {
                Button {
                    moveBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .heavy))
                        .frame(width: 48, height: 52)
                        .background(AppTheme.accentSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)
            }

            Button {
                if step == .review {
                    Task {
                        await onSubmit(draft)
                        dismiss()
                    }
                } else {
                    moveNext()
                }
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text(step == .review ? "Отправить на модерацию" : "Продолжить")
                        Image(systemName: step == .review ? "paperplane.fill" : "chevron.right")
                    }
                }
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(canContinue ? AppTheme.accent : AppTheme.accent.opacity(0.38), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canContinue || isSaving)
        }
        .padding(18)
        .background(.white)
    }

    private var canContinue: Bool {
        switch step {
        case .scenario:
            true
        case .mainInfo:
            !draft.title.trimmedForListing.isEmpty
                && !draft.location.trimmedForListing.isEmpty
                && !draft.description.trimmedForListing.isEmpty
        case .details, .review:
            draft.isValid
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .heavy))
            .foregroundStyle(AppTheme.text)
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(title)
            content()
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.muted.opacity(0.8), lineWidth: 1)
        )
    }

    private func field(_ title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(AppTheme.text)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.sentences)
                .focused($isFieldFocused)
                .padding(13)
                .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
    }

    private func textEditor(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(AppTheme.text)
            ZStack(alignment: .topLeading) {
                TextEditor(text: text)
                    .frame(minHeight: 96)
                    .scrollContentBackground(.hidden)
                    .focused($isFieldFocused)
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.secondaryText.opacity(0.55))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(8)
            .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
    }

    private func chipCloud<Value: CaseIterable & Hashable & Identifiable>(title: String, values: Value.AllCases, selection: Binding<Set<Value>>) -> some View where Value.AllCases: RandomAccessCollection, Value.ID == String, Value: TitledOption {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .heavy))
            FlowLayout(spacing: 8) {
                ForEach(Array(values), id: \.id) { value in
                    SelectionChip(title: value.title, isSelected: selection.wrappedValue.contains(value)) {
                        if selection.wrappedValue.contains(value) {
                            selection.wrappedValue.remove(value)
                        } else {
                            selection.wrappedValue.insert(value)
                        }
                    }
                }
            }
        }
    }

    private func singleChoiceCloud<Value: CaseIterable & Hashable & Identifiable>(title: String, values: Value.AllCases, selection: Binding<Value>) -> some View where Value.AllCases: RandomAccessCollection, Value.ID == String, Value: TitledOption {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .heavy))
            FlowLayout(spacing: 8) {
                ForEach(Array(values), id: \.id) { value in
                    SelectionChip(title: value.title, isSelected: selection.wrappedValue == value) {
                        selection.wrappedValue = value
                    }
                }
            }
        }
    }

    private func reviewRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(AppTheme.secondaryText)
            Spacer(minLength: 12)
            Text(value.isEmpty ? "-" : value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.text)
                .multilineTextAlignment(.trailing)
        }
    }

    private func moveNext() {
        dismissKeyboard()
        guard let next = Step(rawValue: min(step.rawValue + 1, Step.allCases.count - 1)) else { return }
        step = next
    }

    private func moveBack() {
        dismissKeyboard()
        guard let previous = Step(rawValue: max(step.rawValue - 1, 0)) else { return }
        step = previous
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else { return }
        previewImage = image
        draft.photoData = [image.jpegData(compressionQuality: 0.82) ?? data]
    }

    private func applyDefaults(for type: PublicationType) {
        draft.category = draft.resolvedCategory
        draft.isUrgent = type == .urgentHelp || draft.urgencyLevel == .urgent
        if type == .urgentHelp {
            draft.urgencyLevel = .urgent
            draft.isUrgent = true
            draft.publicationFormat = .nonCommercial
        }
        if type == .adoption {
            draft.publicationFormat = .nonCommercial
            draft.pricingMode = .free
            priceText = ""
            draft.pricePerDay = nil
        }
    }

    private func dismissKeyboard() {
        isFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private protocol TitledOption {
    var title: String { get }
}

extension HelpKind: TitledOption {}
extension ListingSubtype: TitledOption {}
extension PricingMode: TitledOption {}
extension BooleanChoice: TitledOption {}
extension HomePreference: TitledOption {}

private struct ScenarioCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(isSelected ? .white : AppTheme.accent)
                    .frame(width: 46, height: 46)
                    .background(isSelected ? AppTheme.accent : AppTheme.accentSoft, in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.muted)
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? AppTheme.accent : AppTheme.muted, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SelectionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(isSelected ? .white : AppTheme.text)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(isSelected ? AppTheme.accent : AppTheme.background, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private extension String {
    var trimmedForListing: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
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
