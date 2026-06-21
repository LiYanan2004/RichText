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
            .defaultScrollAnchor(.bottom)
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

        streamingTask = Task {
            for char in ExampleMarkdown.showcase {
                streamedContent += String(char)
                
                if Task.isCancelled {
                    break
                }
                
                try? await Task.sleep(for: .milliseconds(1))
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
