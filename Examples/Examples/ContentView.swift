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

    var body: some View {
        NavigationStack {
            ScrollView {
                RichTextPlaygroundView(
                    configuration: configuration,
                    isInlineToggleEnabled: $isInlineToggleEnabled,
                    rating: $rating,
                    resetAction: reset
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("RichText Playground")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Controls", systemImage: "slider.horizontal.3") {
                        isPresentingControls = true
                    }
                }
            }
            .sheet(isPresented: $isPresentingControls) {
                NavigationStack {
                    Form {
                        PlaygroundControlsView(configuration: $configuration)
                    }
                    .navigationTitle("Controls")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isPresentingControls = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func reset() {
        configuration = .defaultValue
        isInlineToggleEnabled = true
        rating = 4
    }
}

#Preview {
    ContentView()
}
