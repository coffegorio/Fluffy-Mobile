//
//  ChatListView.swift
//  Fluffy
//

import SwiftUI

struct ChatListView: View {
    let viewModel: MainViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("chats_title")
                    .font(.system(size: 24, weight: .heavy))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                if let errorMessage = viewModel.errorMessage, viewModel.conversations.isEmpty {
                    MarketplaceErrorStateView(message: errorMessage, retry: viewModel.refresh)
                } else if viewModel.isLoading && viewModel.conversations.isEmpty {
                    LazyVStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { _ in
                            ConversationRowSkeleton()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                } else if viewModel.conversations.isEmpty {
                    MarketplaceEmptyStateView(
                        title: "chats_empty_title",
                        subtitle: "chats_empty_subtitle"
                    )
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.conversations) { conversation in
                            Button {
                                viewModel.showConversation(conversation)
                            } label: {
                                ConversationRow(conversation: conversation)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await viewModel.refresh()
        }
        .background(AppTheme.background)
    }
}

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                RemoteImageView(url: conversation.avatarURL)
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())

                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(minWidth: 17, minHeight: 17)
                        .background(AppTheme.accent, in: Capsule())
                        .offset(x: 2, y: -2)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(conversation.name)
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    Text(conversation.time)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Text(conversation.listingTitle)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)

                Text(conversation.lastMessage)
                    .font(.system(size: 13, weight: conversation.unreadCount > 0 ? .semibold : .regular))
                    .foregroundStyle(conversation.unreadCount > 0 ? AppTheme.text : AppTheme.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}
