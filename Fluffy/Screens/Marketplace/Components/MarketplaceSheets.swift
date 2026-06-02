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

struct EditListingSheet: View {
    let listing: Listing
    let isSaving: Bool
    let onSubmit: (ListingEditDraft) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: ListingEditDraft
    @State private var priceText: String
    @FocusState private var isFieldFocused: Bool

    init(
        listing: Listing,
        isSaving: Bool,
        onSubmit: @escaping (ListingEditDraft) async -> Void
    ) {
        self.listing = listing
        self.isSaving = isSaving
        self.onSubmit = onSubmit
        let draft = ListingEditDraft(listing: listing)
        _draft = State(initialValue: draft)
        _priceText = State(initialValue: draft.pricePerDay.map(String.init) ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ListingStatusBadge(status: listing.status)

                    field("Заголовок", text: $draft.title, placeholder: "Коротко о публикации")
                    textEditor("Описание", text: $draft.description, placeholder: "Что важно знать")
                    field("Локация", text: $draft.location, placeholder: "Город, район или ориентир")
                    field("Цена", text: $priceText, placeholder: "Если есть", keyboard: .numberPad)
                        .onChange(of: priceText) { _, value in
                            let digits = value.filter(\.isNumber)
                            draft.pricePerDay = digits.isEmpty ? nil : Int(digits)
                        }

                    Toggle(isOn: $draft.isUrgent) {
                        Label("Срочно", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 15, weight: .heavy))
                    }
                    .tint(AppTheme.accent)
                    .padding(14)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(18)
                .padding(.bottom, 86)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common_cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common_save") {
                        Task {
                            await onSubmit(draft)
                            dismiss()
                        }
                    }
                    .disabled(!draft.isValid || isSaving)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task {
                        await onSubmit(draft)
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                            Text("Сохранить")
                        }
                    }
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(draft.isValid ? AppTheme.accent : AppTheme.accent.opacity(0.38), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(18)
                    .background(.white)
                }
                .buttonStyle(.plain)
                .disabled(!draft.isValid || isSaving)
            }
        }
        .presentationDetents([.large])
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
                .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
    }

    private func textEditor(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(AppTheme.text)
            ZStack(alignment: .topLeading) {
                TextEditor(text: text)
                    .frame(minHeight: 132)
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
            .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
    }
}

struct ReportListingSheet: View {
    let listing: Listing
    let isSaving: Bool
    let onSubmit: (ListingReportDraft) async -> Void

    @State private var draft = ListingReportDraft()
    @FocusState private var isDetailsFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Пожаловаться")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundStyle(AppTheme.text)

                            Text(listing.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(2)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Причина")
                                .font(.system(size: 13, weight: .heavy))

                            ForEach(ReportReason.allCases) { reason in
                                Button {
                                    draft.reason = reason
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(reason.title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(AppTheme.text)

                                        Spacer()

                                        Image(systemName: draft.reason == reason ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(draft.reason == reason ? AppTheme.accent : AppTheme.secondaryText.opacity(0.45))
                                    }
                                    .padding(13)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(draft.reason == .other ? "Детали" : "Детали, если нужно")
                                .font(.system(size: 13, weight: .heavy))

                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $draft.details)
                                    .frame(minHeight: 120)
                                    .scrollContentBackground(.hidden)
                                    .focused($isDetailsFocused)

                                if draft.details.isEmpty {
                                    Text("Опишите, что именно нужно проверить")
                                        .font(.system(size: 16))
                                        .foregroundStyle(AppTheme.secondaryText.opacity(0.55))
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .allowsHitTesting(false)
                                }
                            }
                            .padding(8)
                            .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 90)
                }
                .scrollDismissesKeyboard(.interactively)

                Button {
                    Task {
                        await onSubmit(draft)
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "flag.fill")
                            Text("Отправить жалобу")
                        }
                    }
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(draft.isValid ? AppTheme.danger : AppTheme.danger.opacity(0.38), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!draft.isValid || isSaving)
                .padding(18)
                .background(.white)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Жалоба")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
}

struct ReportTargetSheet: View {
    let target: ReportTarget
    let isSaving: Bool
    let onSubmit: (ReportDraft) async -> Void

    @State private var draft = ReportDraft()
    @FocusState private var isDetailsFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(target.title)
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundStyle(AppTheme.text)

                            Text(target.subtitle)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(3)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Причина")
                                .font(.system(size: 13, weight: .heavy))

                            ForEach(ReportReason.allCases) { reason in
                                Button {
                                    draft.reason = reason
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(reason.title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(AppTheme.text)

                                        Spacer()

                                        Image(systemName: draft.reason == reason ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(draft.reason == reason ? AppTheme.accent : AppTheme.secondaryText.opacity(0.45))
                                    }
                                    .padding(13)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(draft.reason == .other ? "Детали" : "Детали, если нужно")
                                .font(.system(size: 13, weight: .heavy))

                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $draft.details)
                                    .frame(minHeight: 120)
                                    .scrollContentBackground(.hidden)
                                    .focused($isDetailsFocused)

                                if draft.details.isEmpty {
                                    Text("Опишите, что именно нужно проверить")
                                        .font(.system(size: 16))
                                        .foregroundStyle(AppTheme.secondaryText.opacity(0.55))
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .allowsHitTesting(false)
                                }
                            }
                            .padding(8)
                            .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 90)
                }
                .scrollDismissesKeyboard(.interactively)

                Button {
                    Task {
                        await onSubmit(draft)
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "flag.fill")
                            Text("Отправить жалобу")
                        }
                    }
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(draft.isValid ? AppTheme.danger : AppTheme.danger.opacity(0.38), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!draft.isValid || isSaving)
                .padding(18)
                .background(.white)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Жалоба")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
}

struct VerificationRequestSheet: View {
    let isSaving: Bool
    let onSubmit: (String?) async -> Void

    @State private var message = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 58, height: 58)
                        .background(AppTheme.accentSoft, in: Circle())

                    VStack(alignment: .leading, spacing: 7) {
                        Text("Заявка на верификацию")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(AppTheme.text)

                        Text("Расскажите модератору, почему профилю можно доверять: например, вы волонтер, передержка, владелец питомца или представитель приюта.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $message)
                            .frame(minHeight: 160)
                            .scrollContentBackground(.hidden)
                            .focused($isFocused)

                        if message.isEmpty {
                            Text("Например: я волонтер приюта, помогаю с пристройством животных")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.secondaryText.opacity(0.55))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(8)
                    .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                    Spacer(minLength: 0)
                }
                .padding(18)

                Button {
                    Task {
                        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
                        await onSubmit(trimmed.isEmpty ? nil : trimmed)
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("Отправить заявку")
                        }
                    }
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
                .padding(18)
                .background(.white)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Верификация")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
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
    let blockedUsers: [BlockedUser]
    let onSignOut: () -> Void
    let onSignOutEverywhere: () -> Void
    let onDeleteAccount: () async -> Void
    let onUnblockUser: (BlockedUser) async -> Void
    let onUpdateNotificationPreferences: (NotificationPreferences) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var notificationPreferences: NotificationPreferences
    @State private var showsDeleteAccountConfirmation = false

    init(
        action: ProfileMenuAction,
        notificationPreferences: NotificationPreferences,
        blockedUsers: [BlockedUser],
        onSignOut: @escaping () -> Void,
        onSignOutEverywhere: @escaping () -> Void,
        onDeleteAccount: @escaping () async -> Void,
        onUnblockUser: @escaping (BlockedUser) async -> Void,
        onUpdateNotificationPreferences: @escaping (NotificationPreferences) async -> Void
    ) {
        self.action = action
        self.blockedUsers = blockedUsers
        self.onSignOut = onSignOut
        self.onSignOutEverywhere = onSignOutEverywhere
        self.onDeleteAccount = onDeleteAccount
        self.onUnblockUser = onUnblockUser
        self.onUpdateNotificationPreferences = onUpdateNotificationPreferences
        _notificationPreferences = State(initialValue: notificationPreferences)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    content
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common_done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 50, height: 50)
                .background(AppTheme.accentSoft, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch action {
        case .listings:
            EmptyView()
        case .reports:
            EmptyView()
        case .notifications:
            notificationContent
        case .security:
            securityContent
        case .help:
            helpContent
        case .about:
            aboutContent
        }
    }

    private var notificationContent: some View {
        VStack(spacing: 10) {
            settingsToggle("Ответы в чатах", "Когда вам написали по объявлению или передержке", isOn: $notificationPreferences.replies)
            settingsToggle("Модерация", "Статусы объявлений, жалоб и верификации", isOn: $notificationPreferences.moderation)
            settingsToggle("Безопасность", "Важные изменения входа и сессий", isOn: $notificationPreferences.safety)

            Text("Эти настройки сохраняются в профиле и будут использоваться для push-доставки на подключенных устройствах.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .onChange(of: notificationPreferences) { _, value in
            Task {
                await onUpdateNotificationPreferences(value)
            }
        }
    }

    private var securityContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            safetyRow(
                icon: "key.fill",
                title: "Вход по одноразовому коду",
                message: "Пароль не хранится в приложении. Refresh token лежит в Keychain и отзывается при выходе."
            )
            safetyRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Короткие сессии",
                message: "Access token обновляется через backend. Если refresh не проходит, сессия очищается."
            )

            Button(role: .destructive) {
                dismiss()
                onSignOut()
            } label: {
                Label("Выйти на этом устройстве", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .heavy))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {
                dismiss()
                onSignOutEverywhere()
            } label: {
                Label("Выйти на всех устройствах", systemImage: "lock.rotation")
                    .font(.system(size: 15, weight: .heavy))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Divider()
                .padding(.vertical, 4)

            blockedUsersSection

            Divider()
                .padding(.vertical, 4)

            safetyRow(
                icon: "trash.fill",
                title: "Удаление аккаунта",
                message: "Профиль будет обезличен, сессии отозваны, push-устройства отключены, а ваши объявления скрыты из публичной выдачи."
            )

            Button(role: .destructive) {
                showsDeleteAccountConfirmation = true
            } label: {
                Label("Удалить аккаунт", systemImage: "trash")
                    .font(.system(size: 15, weight: .heavy))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .confirmationDialog("Удалить аккаунт?", isPresented: $showsDeleteAccountConfirmation) {
                Button("Удалить аккаунт", role: .destructive) {
                    Task {
                        dismiss()
                        await onDeleteAccount()
                    }
                }
            } message: {
                Text("Это действие нельзя отменить. Ваши объявления исчезнут из выдачи, а вход на текущих устройствах завершится.")
            }
        }
    }

    private var blockedUsersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            safetyRow(
                icon: "hand.raised.fill",
                title: "Заблокированные пользователи",
                message: blockedUsers.isEmpty
                    ? "Заблокированных пользователей нет."
                    : "Разблокируйте пользователя, если хотите снова получать от него сообщения."
            )

            ForEach(blockedUsers) { user in
                HStack(spacing: 12) {
                    RemoteImageView(url: user.avatarURL)
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(user.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(1)
                        if let handle = user.handle, !handle.isEmpty {
                            Text(handle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Button(role: .destructive) {
                        Task {
                            await onUnblockUser(user)
                        }
                    } label: {
                        Text("Разблокировать")
                            .font(.system(size: 12, weight: .heavy))
                    }
                    .buttonStyle(.bordered)
                }
                .padding(12)
                .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius))
            }
        }
    }

    private var helpContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            safetyRow(
                icon: "flag.fill",
                title: "Жалобы на объявления",
                message: "Откройте объявление и нажмите “Пожаловаться”. Жалоба попадет модераторам."
            )
            safetyRow(
                icon: "shield.fill",
                title: "Верификация",
                message: "Отправьте заявку в профиле, если хотите повысить доверие к объявлениям и обращениям."
            )
            safetyRow(
                icon: "message.fill",
                title: "Спорная ситуация",
                message: "Сохраняйте переписку в чате Fluffy. Она помогает модераторам понять контекст."
            )

            Link(destination: URL(string: "mailto:support@fluffy-infra.ru")!) {
                Label("Написать в поддержку", systemImage: "envelope.fill")
                    .font(.system(size: 15, weight: .heavy))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
    }

    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            safetyRow(
                icon: "pawprint.fill",
                title: "Fluffy",
                message: "Маркетплейс помощи животным: объявления, передержки, приюты, чаты и модерация."
            )
            safetyRow(
                icon: "server.rack",
                title: "Backend",
                message: "Авторизация, профили, объявления, жалобы и модерация обрабатываются сервером."
            )
            safetyRow(
                icon: "number",
                title: "Версия",
                message: appVersion
            )
        }
    }

    private func settingsToggle(_ title: String, _ message: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .tint(AppTheme.accent)
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func safetyRow(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 34, height: 34)
                .background(AppTheme.accentSoft, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var iconName: String {
        switch action {
        case .listings: "list.bullet.rectangle"
        case .reports: "flag"
        case .notifications: "bell"
        case .security: "lock.shield"
        case .help: "bubble.left.and.bubble.right"
        case .about: "info.circle"
        }
    }

    private var title: String {
        switch action {
        case .listings: "Мои объявления"
        case .reports: "Мои обращения"
        case .notifications: "Уведомления"
        case .security: "Безопасность"
        case .help: "Помощь"
        case .about: "О Fluffy"
        }
    }

    private var subtitle: String {
        switch action {
        case .listings: ""
        case .reports: ""
        case .notifications: "Выберите, какие события стоит поднимать наверх."
        case .security: "Управляйте текущей сессией и доступом к аккаунту."
        case .help: "Быстрые ответы по безопасным действиям в Fluffy."
        case .about: "Коротко о приложении и текущей сборке."
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
