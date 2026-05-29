//
//  WebSocketService.swift
//  Fluffy
//

import Foundation

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
    private var token: String?
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    weak var delegate: WebSocketServiceDelegate?
    
    func connect(token: String) {
        self.token = token
        guard !isConnected else { return }
        
        guard var components = URLComponents(url: APIConfiguration.live.baseURL, resolvingAgainstBaseURL: false) else { return }
        let newScheme = components.scheme == "https" ? "wss" : "ws"
        components.scheme = newScheme
        components.path = "/api/v1/chats/connect"
        components.queryItems = [URLQueryItem(name: "token", value: token)]
        
        guard let url = components.url else { return }
        
        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: url)
        self.webSocketTask = task
        self.isConnected = true
        
        task.resume()
        listenForMessages()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
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
                    print("WebSocket receive error: \(error)")
                    self.isConnected = false
                    
                    // Reconnect after delay
                    try? await Task.sleep(for: .seconds(3))
                    self.reconnectIfNeeded()
                }
            }
        }
    }
    
    private func handleReceivedData(_ data: Data) {
        do {
            let message = try decoder.decode(WebSocketChatMessage.self, from: data)
            self.delegate?.webSocketService(self, didReceiveMessage: message)
        } catch {
            print("Failed to decode WebSocket message: \(error)")
        }
    }
    
    private func reconnectIfNeeded() {
        guard !isConnected, let token = token else { return }
        connect(token: token)
    }
    
    deinit {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
    }
}
