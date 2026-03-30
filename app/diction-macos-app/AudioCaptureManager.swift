import AVFoundation

class AudioCaptureManager {
    var onAudioChunk: ((Data) -> Void)?

    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 16000,
        channels: 1,
        interleaved: true
    )!

    func start() throws {
        let inputNode = engine.inputNode
        let sourceFormat = inputNode.outputFormat(forBus: 0)

        guard let conv = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            throw AudioCaptureError.converterUnavailable
        }
        converter = conv

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: sourceFormat) { [weak self] buffer, _ in
            self?.process(buffer: buffer, sourceFormat: sourceFormat)
        }

        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }

    private func process(buffer: AVAudioPCMBuffer, sourceFormat: AVAudioFormat) {
        guard let converter else { return }

        let ratio = targetFormat.sampleRate / sourceFormat.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio + 1)
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else { return }

        var inputConsumed = false
        var convError: NSError?
        converter.convert(to: outputBuffer, error: &convError) { _, status in
            if inputConsumed {
                status.pointee = .noDataNow
                return nil
            }
            status.pointee = .haveData
            inputConsumed = true
            return buffer
        }

        guard convError == nil, outputBuffer.frameLength > 0,
              let int16Ptr = outputBuffer.int16ChannelData else { return }

        let byteCount = Int(outputBuffer.frameLength) * MemoryLayout<Int16>.size
        let data = Data(bytes: int16Ptr[0], count: byteCount)
        onAudioChunk?(data)
    }
}

enum AudioCaptureError: LocalizedError {
    case converterUnavailable

    var errorDescription: String? {
        "Could not create audio converter for the required format"
    }
}
