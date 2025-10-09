//
//  Paragraph.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/7.
//

import SwiftUI

// FIXME: Currently just add a line break at the end, not a good one for public usage.
/// A text paragraph.
///
/// Use ``Paragraph`` to separate sections in a ``TextView``.
internal struct Paragraph: TextContentProviding {
    let content: () -> TextContent

    /// Creates a paragraph.
    internal init(@TextContentBuilder content: @escaping () -> TextContent) {
        self.content = content
    }

    /// Produces the underlying text content for the paragraph followed by a
    /// line break.
    internal var textContent: TextContent {
        content()
        LineBreak()
    }
}
