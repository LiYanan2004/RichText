//
//  ContentView.swift
//  Examples
//
//  Created by Yanan Li on 2026/6/18.
//

import SwiftUI

struct ContentView: View {
    @State private var configuration = PlaygroundConfiguration.defaultValue
    @State private var isInlineToggleEnabled = true
    @State private var rating = 4
    @State private var isPresentingControls = false
    @State private var streamedContent = ""
    @State private var isStreaming = false
    @State private var streamingTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ScrollView {
                RichTextPlaygroundView(
                    configuration: configuration,
                    isInlineToggleEnabled: $isInlineToggleEnabled,
                    rating: $rating,
                    streamedContent: streamedContent,
                    resetAction: reset
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("RichText Playground")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        isStreaming ? "Stop Streaming" : "Stream Content",
                        systemImage: isStreaming ? "stop.fill" : "play.fill"
                    ) {
                        if isStreaming {
                            stopStreaming()
                        } else {
                            startStreaming()
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Controls", systemImage: "slider.horizontal.3") {
                        isPresentingControls = true
                    }
                    .popover(isPresented: $isPresentingControls) {
                        Form {
                            PlaygroundControlsView(configuration: $configuration)
                        }
                        .formStyle(.grouped)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                    }
                }
            }
        }
        .onDisappear {
            stopStreaming()
        }
    }

    private func reset() {
        configuration = .defaultValue
        isInlineToggleEnabled = true
        rating = 4
    }

    private func startStreaming() {
        streamingTask?.cancel()
        streamedContent = ""
        isStreaming = true

        streamingTask = Task { @MainActor in
            let source = ExampleMarkdown.showcase
            var currentIndex = source.startIndex

            while currentIndex < source.endIndex {
                let nextIndex = source.index(
                    currentIndex,
                    offsetBy: 12,
                    limitedBy: source.endIndex
                ) ?? source.endIndex
                streamedContent.append(contentsOf: source[currentIndex..<nextIndex])
                currentIndex = nextIndex

                do {
                    try await Task.sleep(for: .milliseconds(16))
                } catch {
                    return
                }
            }

            isStreaming = false
            streamingTask = nil
        }
    }

    private func stopStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        isStreaming = false
    }
}

#Preview {
    ContentView()
}
