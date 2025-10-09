//
//  InlineView.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/8.
//

import SwiftUI

/// A ``TextContent`` representation of a SwiftUI view.
///
/// Use this when you need to provide text replacement.
///
/// In the following example, when user copies the whole text, they will get "Hello **World**
/// (or plain text "Hello World" depends on the paste location)
///
/// ```swift
/// TextView {
///     "Hello"
///     InlineView("**World**") {
///         GlobeGlyph()
///             .id("globe-glyph")
///     }
/// }
/// ```
public struct InlineView<Content: View>: TextContentProviding {
    /// Embedding SwiftUI view.
    public var content: Content
    /// The replacement attributed string.
    public var replacement: AttributedString?

    /// Creates an instance with the given replacement `AttributedString`.
    ///
    /// - parameter replacement: An `AttributedString` serves as the replacement or `nil` if you don't want to create a replacement.
    /// - parameter content: A view builder that builds the content of the view.
    public init(
        _ replacement: AttributedString? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.replacement = replacement
        self.content = content()
    }

    public var textContent: TextContent {
        TextContent(
            .view(
                InlineHostingAttachment(
                    content,
                    replacement: replacement
                )
            )
        )
    }
}

extension InlineView {
    /// Creates an instance with the given string.
    /// Parsing it as markdown first, or fallback to plain sring.
    ///
    /// If you want to use plain string as replacement, use ``init(string:content:)``.
    ///
    /// - parameter replacement: An `String` value that will be parsed as markdown and converted into `AttributedString`, or `nil` if you don't want to create a replacement.
    /// - parameter content: A view builder that builds the content of the view.
    /// - SeeAlso: ``init(string:content:)``
    public init(
        _ replacement: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        var attributedString: AttributedString?
        if let replacement {
            do {
                attributedString = try AttributedString(
                    markdown: replacement,
                    options: AttributedString.MarkdownParsingOptions(
                        allowsExtendedAttributes: true,
                        interpretedSyntax: .inlineOnlyPreservingWhitespace,
                        failurePolicy: .returnPartiallyParsedIfPossible
                    )
                )
            } catch {
                attributedString = AttributedString(replacement)
            }
        }
        
        self.init(attributedString, content: content)
    }
    
    /// Creates an instance with the given string.
    ///
    /// - parameter replacement: An `String` serves as the replacement, or `nil` if you don't want to create a replacement.
    /// - parameter content: A view builder that builds the content of the view.
    public init(
        string: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        let replacement: AttributedString? = if let string {
            AttributedString(stringLiteral: string)
        } else {
            nil
        }
        self.init(replacement, content: content)
    }
}
