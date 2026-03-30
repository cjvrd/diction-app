import Foundation

actor TranscriptionService {
    private var task: URLSessionWebSocketTask?
    private let delegate = WebSocketDelegate()

    private static func makeSession(delegate: WebSocketDelegate) -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }

    private lazy var session = TranscriptionService.makeSession(delegate: delegate)

    private let url = URL(string: "ws://localhost:8080/v1/audio/stream")!

    func connect() {
        task = session.webSocketTask(with: url)
        task?.resume()
    }

    func send(_ data: Data) async throws {
        try await task?.send(.data(data))
    }

    func done() async throws -> String {
        do {
            try await task?.send(.string(#"{"action":"done"}"#))
        } catch {
            throw closeCodeError() ?? TranscriptionError.serverError("Send failed: \(error.localizedDescription)")
        }

        while true {
            let message: URLSessionWebSocketTask.Message
            do {
                guard let received = try await task?.receive() else {
                    throw TranscriptionError.noResponse
                }
                message = received
            } catch let error as TranscriptionError {
                throw error
            } catch {
                throw closeCodeError() ?? TranscriptionError.serverError("Receive failed: \(error.localizedDescription)")
            }

            switch message {
            case .string(let text):
                return try parseTranscription(from: text)
            case .data:
                continue
            @unknown default:
                continue
            }
        }
    }

    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }

    private func closeCodeError() -> TranscriptionError? {
        guard let code = delegate.closeCode else { return nil }
        switch code.rawValue {
        case 4001: return .serverError("Diction backend unavailable — is the model loaded?")
        case 4002: return .serverError("Transcription failed on the server")
        case 4003: return .serverError("Audio too large")
        case 4004: return .serverError("No audio received by server")
        default:   return .serverError("Server closed connection (code \(code.rawValue))")
        }
    }

    private func parseTranscription(from text: String) throws -> String {
        guard let data = text.data(using: .utf8) else { throw TranscriptionError.noResponse }
        let json = try JSONDecoder().decode(ServerMessage.self, from: data)
        if let transcribed = json.text { return transcribed }
        throw TranscriptionError.serverError(json.error ?? "Unknown server error")
    }
}

private final class WebSocketDelegate: NSObject, URLSessionWebSocketDelegate, @unchecked Sendable {
    var closeCode: URLSessionWebSocketTask.CloseCode?

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        self.closeCode = closeCode
    }
}

private struct ServerMessage: Decodable {
    let text: String?
    let error: String?
}

enum TranscriptionError: LocalizedError {
    case noResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .noResponse: return "No transcription received from server"
        case .serverError(let msg): return msg
        }
    }
}
