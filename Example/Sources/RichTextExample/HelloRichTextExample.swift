//
//  HelloRichTextExample.swift
//  RichText
//
//  Created by Yanan Li on 2026/3/19.
//

import SwiftUI
import RichText

struct HelloRichTextExample: View {
    var body: some View {
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
    }
}

#Preview {
    HelloRichTextExample()
}
