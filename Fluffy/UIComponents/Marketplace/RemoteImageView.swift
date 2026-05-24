//
//  RemoteImageView.swift
//  Fluffy
//

import SwiftUI
import UIKit

struct RemoteImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    @State private var phase: LoadingPhase = .idle

    var body: some View {
        Group {
            switch phase {
            case .idle, .loading:
                placeholder
                    .overlay {
                        ProgressView()
                            .tint(AppTheme.accent)
                    }
            case let .success(image):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                placeholder
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(AppTheme.muted)
            .overlay {
                Image(systemName: "pawprint.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent.opacity(0.55))
            }
    }

    private func loadImage() async {
        guard let url else {
            phase = .failure
            return
        }

        if let cached = RemoteImageCache.shared.image(for: url) {
            phase = .success(cached)
            return
        }

        phase = .loading

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                phase = .failure
                return
            }

            RemoteImageCache.shared.insert(image, for: url)
            phase = .success(image)
        } catch {
            phase = .failure
        }
    }
}

private enum LoadingPhase {
    case idle
    case loading
    case success(UIImage)
    case failure
}

private final class RemoteImageCache {
    static let shared = RemoteImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
