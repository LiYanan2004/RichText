//
//  EmbeddedText.swift
//  RichTextExample
//
//  Created by Yanan Li on 2026/3/11.
//

import Foundation
import SwiftUI
import RichText

#Preview("Attributed String") {
    VStack {
        TextView {
            "Hello, "
            AttributedString(
                "RichText",
                attributes: AttributeContainer()
                    .foregroundColor(.blue)
                    .font(.headline)
            )
            "!"
        }
        
        TextView {
            AttributedString(
                "Hello World",
                attributes: AttributeContainer()
                    .inlinePresentationIntent(.emphasized.union(.stronglyEmphasized))
            )
        }
    }
}

#Preview("Embedded Text") {
    TextView {
        Text("Hi, This is **RichText**.")
    }
}

#Preview("Embedded View") {
    VStack {
        TextView {
            "Tap the"
            Space()
            Button("button") {
                print("Button Clicked")
            }
            Space()
            "to continue."
        }

        TextView {
            "Rating: "
            
            // The whole `HStack` will be either selected or deselected.
            HStack(spacing: 2) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
            }
        }
    }
}
