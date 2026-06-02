//
//  MainView.swift
//  Fluffy
//

import Observation
import SwiftUI

struct MainView: View {
    @State var viewModel: MainViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $viewModel.path) {
            ZStack(alignment: .bottomTrailing) {
                tabView(selection: $viewModel.selectedTab)

                if viewModel.selectedTab == .explore {
                    addListingButton
                }
            }
            .navigationBarBackButtonHidden()
            .task {
                await viewModel.load()
            }
            .sheet(item: $viewModel.activeSheet) { sheet in
                sheetView(for: sheet)
            }
            .navigationDestination(for: MarketplaceRoute.self) { route in
                destination(for: route)
            }
        }
    }

    @ViewBuilder
    private func tabView(selection: Binding<MainTab>) -> some View {
        TabView(selection: selection) {
            MarketplaceHomeView(viewModel: viewModel)
                .tag(MainTab.home)
                .tabItem {
                    Label("tab_home", systemImage: MainTab.home.systemImage)
                }

            ExploreView(viewModel: viewModel)
                .tag(MainTab.explore)
                .tabItem {
                    Label("tab_explore", systemImage: MainTab.explore.systemImage)
                }

            ChatListView(viewModel: viewModel)
                .tag(MainTab.chats)
                .tabItem {
                    Label("tab_chats", systemImage: MainTab.chats.systemImage)
                }
                .badge(viewModel.totalUnreadCount)

            FavoritesView(viewModel: viewModel)
                .tag(MainTab.favorites)
                .tabItem {
                    Label("tab_favorites", systemImage: MainTab.favorites.systemImage)
                }

            ProfileView(viewModel: viewModel)
                .tag(MainTab.profile)
                .tabItem {
                    Label("tab_profile", systemImage: MainTab.profile.systemImage)
                }
        }
        .tint(AppTheme.accent)
        .background(AppTheme.background)
    }

    @ViewBuilder
    private func destination(for route: MarketplaceRoute) -> some View {
        switch route {
        case let .listingDetail(id):
            if let listing = viewModel.listing(withID: id) {
                ListingDetailView(viewModel: viewModel, listing: listing)
            } else {
                MissingContentView(title: "detail_missing_listing")
            }
        case let .conversation(id):
            if viewModel.conversation(withID: id) != nil {
                ConversationView(viewModel: viewModel, conversationID: id)
            } else {
                MissingContentView(title: "chat_missing_conversation")
            }
        case .shelters:
            SheltersView(viewModel: viewModel)
        case .petSitting:
            PetSittingView(viewModel: viewModel)
        case .map:
            MarketplaceMapView(viewModel: viewModel)
        case .myListings:
            MyListingsView(viewModel: viewModel)
        case .myReports:
            MyReportsView(viewModel: viewModel)
        }
    }

    private var addListingButton: some View {
        Button {
            viewModel.showAddListing()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AppTheme.accent, in: Circle())
                .shadow(color: AppTheme.accent.opacity(0.35), radius: 14, y: 8)
        }
        .accessibilityLabel(Text("add_listing"))
        .padding(.trailing, 18)
        .padding(.bottom, 82)
    }

    @ViewBuilder
    private func sheetView(for sheet: MarketplaceSheet) -> some View {
        switch sheet {
        case .addListing:
            AddListingSheet(isSaving: viewModel.isPerformingAction) { draft in
                await viewModel.createListing(from: draft)
            }
        case let .editListing(listing):
            EditListingSheet(listing: listing, isSaving: viewModel.isPerformingAction) { draft in
                await viewModel.updateListing(listing, draft: draft)
            }
        case let .reportListing(listing):
            ReportListingSheet(listing: listing, isSaving: viewModel.isPerformingAction) { draft in
                await viewModel.reportListing(listing, draft: draft)
            }
        case let .reportTarget(target):
            ReportTargetSheet(target: target, isSaving: viewModel.isPerformingAction) { draft in
                await viewModel.reportTarget(target, draft: draft)
            }
        case .verificationRequest:
            VerificationRequestSheet(isSaving: viewModel.isPerformingAction) { message in
                await viewModel.requestProfileVerification(message: message)
            }
        case let .status(title, message):
            MarketplaceStatusSheet(title: LocalizedStringKey(title), message: LocalizedStringKey(message))
        case let .profileAction(action):
            ProfileActionSheet(
                action: action,
                notificationPreferences: viewModel.notificationPreferences,
                blockedUsers: viewModel.blockedUsers,
                onSignOut: viewModel.signOut,
                onSignOutEverywhere: viewModel.signOutEverywhere,
                onDeleteAccount: viewModel.deleteAccount,
                onUnblockUser: viewModel.unblockUser,
                onUpdateNotificationPreferences: viewModel.updateNotificationPreferences
            )
        }
    }
}

private struct MissingContentView: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .foregroundStyle(AppTheme.secondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background)
    }
}
