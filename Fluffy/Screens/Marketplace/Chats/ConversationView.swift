//
//  ConversationView.swift
//  Fluffy
//

import Observation
import PhotosUI
import SwiftUI

struct ConversationView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: MainViewModel
    let conversationID: String

    @State private var draft = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    var body: some View {
        @Bindable var viewModel = viewModel

        if let conversation = viewModel.conversation(withID: conversationID) {
            VStack(spacing: 0) {
                header(conversation)
                messages(conversation)
                composer
            }
            .background(AppTheme.background)
            .navigationBarBackButtonHidden()
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        viewModel.sendPhotoMessage(data: data, in: conversationID)
                    }
                    selectedPhotoItem = nil
                }
            }
        } else {
            Text("chat_missing_conversation")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.background)
                .navigationBarBackButtonHidden()
        }
    }

    private func header(_ conversation: Conversation) -> some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.muted, in: Circle())
            }
            .accessibilityLabel(Text("common_back"))

            RemoteImageView(url: conversation.avatarURL)
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.name)
                    .font(.system(size: 15, weight: .bold))
                Text(conversation.listingTitle)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                viewModel.showCallPlaceholder()
            } label: {
                Image(systemName: "phone.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.muted, in: Circle())
            }
            .accessibilityLabel(Text("common_call"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)
        }
    }

    private func messages(_ conversation: Conversation) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 9) {
                    ForEach(conversation.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
            .onChange(of: conversation.messages.count) {
                if let lastID = conversation.messages.last?.id {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.muted, in: Circle())
            }
            .accessibilityLabel(Text("chat_attach_photo"))

            TextField("chat_message_placeholder", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(AppTheme.muted, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                .accessibilityIdentifier("chat_message_field")

            Button {
                viewModel.sendMessage(draft, in: conversationID)
                draft = ""
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.accent, in: Circle())
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            .accessibilityLabel(Text("chat_send"))
        }
        .padding(12)
        .background(AppTheme.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)
        }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    private var isImageMessage: Bool {
        guard let url = URL(string: message.text) else { return false }
        let ext = url.pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "webp", "gif"].contains(ext) || message.text.contains("/uploads/")
    }

    var body: some View {
        HStack {
            if message.sender == .me {
                Spacer(minLength: 48)
            }

            VStack(alignment: message.sender == .me ? .trailing : .leading, spacing: 4) {
                if isImageMessage, let url = URL(string: message.text) {
                    RemoteImageView(url: url)
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 220, maxHeight: 220)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 16,
                                bottomLeadingRadius: message.sender == .me ? 16 : 4,
                                bottomTrailingRadius: message.sender == .me ? 4 : 16,
                                topTrailingRadius: 16
                            )
                        )
                        .overlay(alignment: .bottomTrailing) {
                            Text(message.time)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.45), in: Capsule())
                                .padding(8)
                        }
                        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
                } else {
                    VStack(alignment: message.sender == .me ? .trailing : .leading, spacing: 4) {
                        Text(message.text)
                            .font(.system(size: 15))
                            .foregroundStyle(message.sender == .me ? .white : AppTheme.text)

                        Text(message.time)
                            .font(.system(size: 10))
                            .foregroundStyle(message.sender == .me ? .white.opacity(0.75) : AppTheme.secondaryText)
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(
                        message.sender == .me ? AppTheme.accent : AppTheme.surface,
                        in: UnevenRoundedRectangle(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: message.sender == .me ? 18 : 5,
                            bottomTrailingRadius: message.sender == .me ? 5 : 18,
                            topTrailingRadius: 18
                        )
                    )
                    .shadow(color: .black.opacity(message.sender == .me ? 0 : 0.04), radius: 7, y: 3)
                }
            }

            if message.sender == .them {
                Spacer(minLength: 48)
            }
        }
    }
}
