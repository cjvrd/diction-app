//
//  ContentView.swift
//  diction-macos-app
//
//  Created by Christian Virdo on 29/3/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = ContentViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            statusLabel
            recordButton
            Spacer()
        }
        .padding(32)
        .frame(minWidth: 420, minHeight: 320)
        .overlay(alignment: .bottom) {
            resultView
                .padding([.horizontal, .bottom], 32)
        }
    }

    private var statusText: String {
        switch viewModel.state {
        case .idle:         return "Tap to record"
        case .recording:    return "Recording…"
        case .transcribing: return "Transcribing…"
        case .result:       return "Done"
        case .error:        return "Error"
        }
    }

    private var isRecording: Bool {
        if case .recording = viewModel.state { return true }
        return false
    }

    private var isTranscribing: Bool {
        if case .transcribing = viewModel.state { return true }
        return false
    }

    private var statusLabel: some View {
        Text(statusText)
            .foregroundStyle(.secondary)
            .font(.subheadline)
    }

    private var recordButton: some View {
        Button {
            Task { await viewModel.toggleRecording() }
        } label: {
            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: 30))
                .foregroundStyle(.white)
                .frame(width: 80, height: 80)
                .background(isRecording ? Color.red : Color.accentColor)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(isTranscribing)
        .scaleEffect(isRecording ? 1.08 : 1.0)
        .animation(
            isRecording
                ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
                : .default,
            value: isRecording
        )
    }

    @ViewBuilder
    private var resultView: some View {
        switch viewModel.state {
        case .result(let text):
            VStack(alignment: .leading, spacing: 8) {
                ScrollView {
                    Text(text)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .frame(maxHeight: 180)
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack {
                    Button("Record again") {
                        Task { await viewModel.toggleRecording() }
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                    }
                    .buttonStyle(.bordered)
                }
            }
        case .error(let message):
            Text(message)
                .foregroundStyle(.red)
                .font(.callout)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        default:
            EmptyView()
        }
    }
}

#Preview {
    ContentView()
}
