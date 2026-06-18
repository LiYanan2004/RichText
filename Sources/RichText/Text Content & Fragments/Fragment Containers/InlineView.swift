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
/// In the following example, when user copies the whole text, they will get "Hello **World**"
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
    /// The replacement attributed string.
    public var replacement: AttributedString?
    /// The identifier that associated with the view.
    public var id: AnyHashable?
    /// The hosted attachment sizing policy.
    public var sizing: HostedAttachmentSizing
    /// Embedding SwiftUI view.
    @ViewBuilder public var content: Content

    /// Creates an instance with the given replacement `AttributedString`.
    ///
    /// - parameter id: A `Hashable` identifier associated to this view.
    /// - parameter replacement: An `AttributedString` serves as the replacement or `nil` if you don't want to create a replacement.
    /// - parameter sizing: A sizing policy for the hosted attachment.
    /// - parameter content: A view builder that builds the content of the view.
    public init<ID: Hashable>(
        id: ID,
        replacement: AttributedString? = nil,
        sizing: HostedAttachmentSizing = .intrinsic,
        content: @escaping () -> Content
    ) {
        self.id = AnyHashable(id)
        self.replacement = replacement
        self.sizing = sizing
        self.content = content()
    }
    
    /// Creates an instance with the given replacement `AttributedString`.
    ///
    /// - parameter replacement: An `AttributedString` serves as the replacement or `nil` if you don't want to create a replacement.
    /// - parameter sizing: A sizing policy for the hosted attachment.
    /// - parameter content: A view builder that builds the content of the view.
    public init(
        replacement: AttributedString? = nil,
        sizing: HostedAttachmentSizing = .intrinsic,
        content: @escaping () -> Content
    ) {
        self.id = nil
        self.replacement = replacement
        self.sizing = sizing
        self.content = content()
    }

    public var textContent: TextContent {
        TextContent(
            .view(
                InlineHostingAttachment(
                    content,
                    id: id,
                    replacement: replacement,
                    sizing: sizing
                )
            )
        )
    }
}

extension InlineView {
    /// Creates an instance with the given string and parses it as Markdown, or falls back to a plain string.
    ///
    /// If you want to use plain string as replacement, use ``init(string:content:)``.
    ///
    /// - parameter replacement: A `String` value that is parsed as Markdown and converted into `AttributedString`, or `nil` if you don't want to create a replacement.
    /// - parameter sizing: A sizing policy for the hosted attachment.
    /// - parameter content: A view builder that builds the content of the view.
    /// - SeeAlso: ``init(string:content:)``
    public init(
        _ replacement: String? = nil,
        sizing: HostedAttachmentSizing = .intrinsic,
        @ViewBuilder content: @escaping () -> Content
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
        
        self.init(replacement: attributedString, sizing: sizing, content: content)
    }
    
    /// Creates an instance with the given string.
    ///
    /// - parameter replacement: A `String` serves as the replacement, or `nil` if you don't want to create a replacement.
    /// - parameter sizing: A sizing policy for the hosted attachment.
    /// - parameter content: A view builder that builds the content of the view.
    public init(
        string: String? = nil,
        sizing: HostedAttachmentSizing = .intrinsic,
        @ViewBuilder content: @escaping () -> Content
    ) {
        let replacement: AttributedString? = if let string {
            AttributedString(stringLiteral: string)
        } else {
            nil
        }
        self.init(replacement: replacement, sizing: sizing, content: content)
    }
}
