//
//  EmbedSwiftUIViewExample.swift
//  RichText
//
//  Created by Yanan Li on 2026/3/19.
//

import RichText
import SwiftUI

struct EmbedSwiftUIViewExample: View {
    var body: some View {
        TextView {
            "This is a "
            InlineView(id: "toggle", replacement: "toggle") {
                Toggle("Toggle", isOn: .constant(false))
            }
            " embedded around text."
            
            LineBreak(2)
            
            "Rating: "
            
            // The whole `HStack` will be either selected or deselected.
            HStack(spacing: 2) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
            }
            
            Space()
            
            Button("Reset") {
                print("Reset Button Clicked")
            }
            .offset(y: 2)
        }
    }
}

#Preview {
    EmbedSwiftUIViewExample()
        .scenePadding()
}
