//
//  Paragraph.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/7.
//

import SwiftUI

public struct Paragraph: TextContentProviding {
    let content: () -> TextContent

    public init(@TextContentBuilder content: @escaping () -> TextContent) {
        self.content = content
    }

    public var textContent: TextContent {
        content()
        LineBreak()
    }
}
