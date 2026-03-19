//
//  InlinePresentationExample.swift
//  RichText
//
//  Created by Yanan Li on 2026/3/19.
//

import SwiftUI
import RichText

struct InlinePresentationExample: View {
    var body: some View {
        TextView {
            try! AttributedString(
                markdown: "**Bold**, *Italic*"
            )
            LineBreak()
            AttributedString(
                "Bold, Italic, Strikethrough, code",
                attributes: AttributeContainer()
                    .inlinePresentationIntent([.emphasized, .code, .stronglyEmphasized, .strikethrough])
            )
        }
        .multilineTextAlignment(.center)
    }
}
