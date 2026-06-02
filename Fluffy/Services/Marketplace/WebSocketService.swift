//
//  WebSocketService.swift
//  Fluffy
//

import Foundation
import OSLog

struct WebSocketChatMessage: Decodable, Hashable {
    let id: String
    let chatId: String
    let senderId: String
    let text: String
    let createdAt: Date?
}

@MainActor
protocol WebSocketServiceDelegate: AnyObject {
    func webSocketService(_ service: WebSocketService, didReceiveMessage message: WebSocketChatMessage)
}

@MainActor
final class WebSocketService {
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    private var isConnecting = false
    private var shouldReconnect = false
    private var tokenProvider: (() async throws -> String)?
    private let logger = Logger(subsystem: "ru.fluffy.app", category: "websocket")
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    weak var delegate: WebSocketServiceDelegate?
    
    func connect(tokenProvider: @escaping () async throws -> String) {
        self.tokenProvider = tokenProvider
        shouldReconnect = true
        guard !isConnected, !isConnecting else { return }

        Task { @MainActor in
            await openConnection()
        }
    }

    func disconnect() {
        shouldReconnect = false
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        isConnecting = false
    }

    private func openConnection() async {
        guard !isConnected, !isConnecting, shouldReconnect else { return }
        guard let tokenProvider else { return }

        isConnecting = true

        let token: String
        do {
            token = try await tokenProvider()
        } catch {
            logger.error("WebSocket token refresh failed: \(String(describing: error), privacy: .private)")
            isConnecting = false
            if error.isAuthenticationFailure {
                shouldReconnect = false
                return
            }
            await scheduleReconnect()
            return
        }

        guard var components = URLComponents(url: APIConfiguration.live.baseURL, resolvingAgainstBaseURL: false) else {
            isConnecting = false
            return
        }
        let newScheme = components.scheme == "https" ? "wss" : "ws"
        components.scheme = newScheme
        components.path = "/api/v1/chats/connect"
        
        guard let url = components.url else {
            isConnecting = false
            return
        }
        
        let session = URLSession(configuration: .default)
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(UUID().uuidString, forHTTPHeaderField: APIClient.requestIDHeader)
        let task = session.webSocketTask(with: request)
        self.webSocketTask = task
        self.isConnected = true
        self.isConnecting = false
        
        task.resume()
        listenForMessages()
    }
    
    private func listenForMessages() {
        guard let task = webSocketTask, isConnected else { return }
        
        task.receive { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                guard self.isConnected else { return }
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        if let data = text.data(using: .utf8) {
                            self.handleReceivedData(data)
                        }
                    case .data(let data):
                        self.handleReceivedData(data)
                    @unknown default:
                        break
                    }
                    
                    // Continue listening
                    self.listenForMessages()
                    
                case .failure(let error):
                    self.logger.error("WebSocket receive failed: \(String(describing: error), privacy: .private)")
                    self.isConnected = false
                    await self.scheduleReconnect()
                }
            }
        }
    }
    
    private func handleReceivedData(_ data: Data) {
        do {
            let message = try decoder.decode(WebSocketChatMessage.self, from: data)
            self.delegate?.webSocketService(self, didReceiveMessage: message)
        } catch {
            logger.error("WebSocket message decoding failed: \(String(describing: error), privacy: .private)")
        }
    }
    
    private func scheduleReconnect() async {
        guard shouldReconnect else { return }
        try? await Task.sleep(for: .seconds(3))
        await openConnection()
    }
    
    deinit {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
    }
}

private extension Error {
    var isAuthenticationFailure: Bool {
        guard let error = self as? APIClientError else { return false }
        switch error {
        case .httpStatus(401, _):
            return true
        case let .api(code, _, _):
            return code == "unauthorized" || code == "unauthenticated"
        default:
            return false
        }
    }
}
