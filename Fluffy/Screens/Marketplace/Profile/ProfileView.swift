//
//  ProfileView.swift
//  Fluffy
//

import SwiftUI

struct ProfileView: View {
    let viewModel: MainViewModel

    private let menuItems: [(LocalizedStringKey, String, ProfileMenuAction)] = [
        ("profile_menu_listings", "list.bullet.rectangle", .listings),
        ("Мои обращения", "flag", .reports),
        ("profile_menu_notifications", "bell", .notifications),
        ("profile_menu_security", "lock.shield", .security),
        ("profile_menu_help", "bubble.left.and.bubble.right", .help),
        ("profile_menu_about", "info.circle", .about)
    ]

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("tab_profile")
                        .font(.system(size: 24, weight: .heavy))

                    if let errorMessage = viewModel.errorMessage, viewModel.profile == nil {
                        MarketplaceErrorStateView(message: errorMessage, retry: viewModel.refresh)
                    } else if let profile = viewModel.profile {
                        profileHeader(profile)
                        if viewModel.shouldShowVerificationNotice {
                            verificationNotice
                        }
                        stats(profile)
                        myListings
                        menu
                        signOutButton
                    } else if viewModel.isLoading {
                        ProfileSkeletonView()
                    } else {
                        MarketplaceErrorStateView(message: String(localized: "marketplace_load_error"), retry: viewModel.refresh)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 22)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollIndicators(.hidden)
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private func profileHeader(_ profile: UserProfile) -> some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                RemoteImageView(url: profile.avatarURL)
                    .frame(width: 82, height: 82)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.accent, lineWidth: 2))

                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 23, height: 23)
                    .background(AppTheme.accent, in: Circle())
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(profile.name)
                    .font(.system(size: 20, weight: .heavy))
                Text("\(profile.handle) · \(profile.city)")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.secondaryText)
                HStack(spacing: 8) {
                    RatingView(rating: profile.rating)
                    Text("\(profile.reviews) \(String(localized: "profile_reviews"))")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Spacer()
        }
    }

    private var verificationNotice: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: verificationIcon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(verificationTint)
                .frame(width: 38, height: 38)
                .background(verificationTint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey(verificationTitle))
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                Text(LocalizedStringKey(verificationMessage))
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if canRequestVerification {
                    Button {
                        viewModel.showVerificationRequest()
                    } label: {
                        Label("Отправить заявку", systemImage: "paperplane.fill")
                            .font(.system(size: 13, weight: .heavy))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                    .disabled(viewModel.isPerformingAction)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private var verificationIcon: String {
        switch viewModel.currentVerificationStatus {
        case .notStarted: "shield.lefthalf.filled"
        case .pending: "clock.fill"
        case .approved: "checkmark.shield.fill"
        case .rejected: "exclamationmark.shield.fill"
        }
    }

    private var verificationTint: Color {
        switch viewModel.currentVerificationStatus {
        case .notStarted: AppTheme.accent
        case .pending: .orange
        case .approved: AppTheme.success
        case .rejected: AppTheme.danger
        }
    }

    private var verificationTitle: String {
        switch viewModel.currentVerificationStatus {
        case .notStarted: "Подтвердите профиль"
        case .pending: "Заявка на проверке"
        case .approved: "Профиль подтвержден"
        case .rejected: "Заявку нужно обновить"
        }
    }

    private var verificationMessage: String {
        switch viewModel.currentVerificationStatus {
        case .notStarted:
            "Верификация повышает доверие к объявлениям и обращениям. Заявку проверяет модератор."
        case .pending:
            "Мы уже отправили заявку модераторам. Статус обновится после проверки."
        case .approved:
            "Ваш профиль подтвержден."
        case .rejected:
            "Модератор отклонил прошлую заявку. Отправьте новую с уточнением, кто вы и чем занимаетесь."
        }
    }

    private var canRequestVerification: Bool {
        [.notStarted, .rejected].contains(viewModel.currentVerificationStatus)
    }

    private func stats(_ profile: UserProfile) -> some View {
        HStack(spacing: 8) {
            ProfileStat(value: "\(profile.listingsCount)", title: "profile_stat_listings")
            ProfileStat(value: "\(profile.dealsCount)", title: "profile_stat_deals")
            ProfileStat(value: "\(profile.daysOnPlatform)", title: "profile_stat_days")
        }
    }

    private var myListings: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("profile_my_listings")
                    .font(.system(size: 17, weight: .heavy))

                Spacer()

                Button {
                    viewModel.showMyListings()
                } label: {
                    Label("Все", systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                        .font(.system(size: 13, weight: .heavy))
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.accent)
            }

            if viewModel.myListings.isEmpty {
                Text("После публикации объявления появятся здесь со статусом модерации.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                    .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12))
            }

            ForEach(viewModel.myListings.prefix(3)) { listing in
                Button {
                    viewModel.showListing(listing)
                } label: {
                    HStack(spacing: 12) {
                        RemoteImageView(url: listing.imageURL)
                            .frame(width: 54, height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 5) {
                            Text(listing.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.text)
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                ListingBadge(category: listing.category)
                                ListingStatusBadge(status: listing.status)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(12)
                    .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                    .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12), isInteractive: true)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var menu: some View {
        VStack(spacing: 0) {
            ForEach(Array(menuItems.enumerated()), id: \.offset) { index, item in
                Button {
                    viewModel.showProfileAction(item.2)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.1)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 24)

                        Text(item.0)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.text)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 15)
                }
                .buttonStyle(.plain)

                if index < menuItems.count - 1 {
                    Divider()
                        .padding(.leading, 50)
                }
            }
        }
        .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private var signOutButton: some View {
        Button(role: .destructive) {
            viewModel.signOut()
        } label: {
            Label("profile_sign_out", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
        }
        .buttonStyle(.bordered)
    }
}

private struct ProfileStat: View {
    let value: String
    let title: LocalizedStringKey

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .heavy))
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

private enum MyListingsFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case active
    case rejected
    case closed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Все"
        case .pending: ListingStatus.pending.title
        case .active: ListingStatus.active.title
        case .rejected: ListingStatus.rejected.title
        case .closed: ListingStatus.closed.title
        }
    }

    func contains(_ listing: Listing) -> Bool {
        switch self {
        case .all: true
        case .pending: listing.status == .pending
        case .active: listing.status == .active
        case .rejected: listing.status == .rejected
        case .closed: listing.status == .closed
        }
    }
}

struct MyListingsView: View {
    let viewModel: MainViewModel

    @State private var filter: MyListingsFilter = .all
    @State private var listingToClose: Listing?
    @State private var listingToDelete: Listing?

    private var filteredListings: [Listing] {
        viewModel.myListings.filter { filter.contains($0) }
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    filterBar

                    if filteredListings.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredListings) { listing in
                            MyListingRow(
                                listing: listing,
                                isBusy: viewModel.isPerformingAction,
                                onOpen: { viewModel.showListing(listing) },
                                onEdit: { viewModel.showEditListing(listing) },
                                onClose: { listingToClose = listing },
                                onDelete: { listingToDelete = listing }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
            .refreshable {
                await viewModel.refreshMyListings()
            }
        }
        .navigationTitle("Мои объявления")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.myListings.isEmpty {
                await viewModel.refreshMyListings()
            }
        }
        .confirmationDialog("Закрыть объявление?", isPresented: closeDialogBinding) {
            if let listingToClose {
                Button("Закрыть", role: .destructive) {
                    viewModel.closeListing(listingToClose)
                }
            }
        } message: {
            Text("Оно останется в истории, но перестанет принимать отклики.")
        }
        .confirmationDialog("Удалить объявление?", isPresented: deleteDialogBinding) {
            if let listingToDelete {
                Button("Удалить", role: .destructive) {
                    viewModel.deleteListing(listingToDelete)
                }
            }
        } message: {
            Text("Это действие нельзя отменить.")
        }
    }

    private var closeDialogBinding: Binding<Bool> {
        Binding(
            get: { listingToClose != nil },
            set: { isPresented in
                if !isPresented {
                    listingToClose = nil
                }
            }
        )
    }

    private var deleteDialogBinding: Binding<Bool> {
        Binding(
            get: { listingToDelete != nil },
            set: { isPresented in
                if !isPresented {
                    listingToDelete = nil
                }
            }
        )
    }

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(MyListingsFilter.allCases) { item in
                    Button {
                        filter = item
                    } label: {
                        Text(LocalizedStringKey(item.title))
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(filter == item ? .white : AppTheme.text)
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .background(filter == item ? AppTheme.accent : AppTheme.surface, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: filter == .all ? "list.bullet.rectangle" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(AppTheme.accent)

            Text(filter == .all ? "Публикаций пока нет" : "В этом статусе пусто")
                .font(.system(size: 18, weight: .heavy))

            Text(filter == .all ? "Создайте объявление, и оно появится здесь сразу после отправки на модерацию." : "Попробуйте выбрать другой статус.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
    }
}

private struct MyListingRow: View {
    let listing: Listing
    let isBusy: Bool
    let onOpen: () -> Void
    let onEdit: () -> Void
    let onClose: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onOpen) {
                HStack(alignment: .top, spacing: 12) {
                    RemoteImageView(url: listing.imageURL)
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .top, spacing: 8) {
                            Text(listing.title)
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundStyle(AppTheme.text)
                                .lineLimit(2)

                            Spacer(minLength: 0)

                            ListingStatusBadge(status: listing.status)
                        }

                        Text(listing.location)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(1)

                        ListingBadge(category: listing.category)
                    }
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Label("Править", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isBusy || listing.status == .deleted)

                Button(action: onClose) {
                    Label("Закрыть", systemImage: "archivebox")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isBusy || listing.status == .closed || listing.status == .deleted)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .frame(width: 42)
                }
                .buttonStyle(.bordered)
                .disabled(isBusy || listing.status == .deleted)
            }
            .font(.system(size: 13, weight: .heavy))
        }
        .padding(14)
        .background(AppTheme.surface.opacity(0.78), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

struct ListingStatusBadge: View {
    let status: ListingStatus

    var body: some View {
        Label(LocalizedStringKey(status.title), systemImage: status.systemImage)
            .font(.system(size: 11, weight: .heavy))
            .lineLimit(1)
            .foregroundStyle(status.tint)
            .padding(.horizontal, 8)
            .frame(height: 25)
            .background(status.tint.opacity(0.12), in: Capsule())
    }
}

struct MyReportsView: View {
    let viewModel: MainViewModel

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if viewModel.myReports.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.myReports, id: \.id) { report in
                            ReportRow(report: report)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
            .refreshable {
                await viewModel.refreshMyReports()
            }
        }
        .navigationTitle("Мои обращения")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.myReports.isEmpty {
                await viewModel.refreshMyReports()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "flag")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(AppTheme.accent)

            Text("Обращений пока нет")
                .font(.system(size: 18, weight: .heavy))

            Text("Если объявление кажется опасным или нарушает правила, откройте его и отправьте жалобу.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
    }
}

private struct ReportRow: View {
    let report: ReportResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: report.status.systemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(report.status.tint)
                    .frame(width: 34, height: 34)
                    .background(report.status.tint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(report.reason)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                        .lineLimit(2)

                    (Text(LocalizedStringKey(report.targetType.title)) + Text(" · \(formattedDate)"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer(minLength: 0)

                ReportStatusBadge(status: report.status)
            }

            if let details = report.details?.trimmingCharacters(in: .whitespacesAndNewlines), !details.isEmpty {
                Text(details)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(3)
            }
        }
        .padding(14)
        .background(AppTheme.surface.opacity(0.78), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private var formattedDate: String {
        guard let date = report.createdAt else { return "дата неизвестна" }
        return Self.dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct ReportStatusBadge: View {
    let status: ReportStatus

    var body: some View {
        Text(LocalizedStringKey(status.title))
            .font(.system(size: 11, weight: .heavy))
            .lineLimit(1)
            .foregroundStyle(status.tint)
            .padding(.horizontal, 8)
            .frame(height: 25)
            .background(status.tint.opacity(0.12), in: Capsule())
    }
}
