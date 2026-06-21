//
//  TextLayoutEngineEnvironmentKey.swift
//  RichText
//
//  Created by Yanan Li on 2026/6/20.
//

import SwiftUI

extension View {
    /// Sets the text layout engine used by ``RichText/TextView`` within this view hierarchy.
    public nonisolated func textLayoutEngine<Engine>(
        _ engine: Engine
    ) -> some View where Engine: TextLayoutEngine {
        environment(\.usesTextLayoutManager, Engine.usesTextLayoutManager)
    }
}

private struct TextLayoutEngineEnvironmentKey: EnvironmentKey {
    static let defaultValue = TextKit1TextLayoutEngine.usesTextLayoutManager
}

extension EnvironmentValues {
    var usesTextLayoutManager: Bool {
        get { self[TextLayoutEngineEnvironmentKey.self] }
        set { self[TextLayoutEngineEnvironmentKey.self] = newValue }
    }
}
