import Foundation
import Observation

enum DictationState {
    case idle
    case recording
    case transcribing
    case result(String)
    case error(String)
}

@Observable
@MainActor
class ContentViewModel {
    var state: DictationState = .idle

    private let audio = AudioCaptureManager()
    private let service = TranscriptionService()

    func toggleRecording() async {
        switch state {
        case .idle, .result, .error:
            await startRecording()
        case .recording:
            await stopRecording()
        case .transcribing:
            break
        }
    }

    private func startRecording() async {
        await service.connect()

        audio.onAudioChunk = { [service] data in
            Task { try? await service.send(data) }
        }

        do {
            try audio.start()
            state = .recording
        } catch {
            state = .error(error.localizedDescription)
            await service.disconnect()
        }
    }

    private func stopRecording() async {
        audio.stop()
        state = .transcribing

        do {
            let text = try await service.done()
            state = .result(text)
        } catch {
            state = .error(error.localizedDescription)
        }

        await service.disconnect()
    }
}
