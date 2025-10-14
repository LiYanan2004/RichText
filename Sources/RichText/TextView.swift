//
//  TextView.swift
//  RichText
//
//  Created by Yanan Li on 2025/8/24.
//

import SwiftUI

/// A rich text container that renders plain strings, attributed strings, and
/// inline SwiftUI views together while offers the same text selection experience.
///
/// You declare the text content by using:
/// - a type that conforms to `StringProtocol` for plain-text fragment
///     - `String`
///     - `Substring`
///     - etc.
/// - `Foundation.AttributedString` for attributed string (or rich text) fragment
/// - `SwiftUI.View` for platform view fragment (without replacement text)
/// - ``InlineView`` for platform view fragment (with optional replacement)
///     - This would have the same effect as previous one, if you choose not providing a replacement text.
///
/// Here is a simple example of ``TextView``:
///
/// ```swift
/// TextView {
///     "Tap the "
///     InlineView("button") {
///         Button("button") {
///             print("Button Clicked")
///         }
///         .id("button")
///     }
///     " to continue."
/// }
/// ```
///
/// By describing the ``TextContent``, you will be able to embed native view while still getting the text selection experience.
///
/// When you select the button and copy it, you will get the replacement text -- here, "button" -- if you specified one.
///
/// ### Additional notes on custom view embedding
///
/// Providing an explicit ``id(_:)`` for each view is recommended, as it helps reduce unnecessary re-layouts and would help improve performance.
///
/// Plus, if your view owns a state (e.g. you're using `@State`, `@StateObject`, etc. within the view), the identity is also used to preserve the state of a view.
///
/// For more information, check out ``InlineHostingAttachment/id``
///
/// ### SwiftUI View modifiers
///
/// Most of the text-styling view modifiers should work seamlessly with `TextView`.
///
/// Some text modifiers, for example: `baselineOffset(_:)`, `kerning(_:)`, `bold(_:)`, etc., are not available since SwiftUI does not expose environment values for those properties. For these use cases, use `AttributedString` instead.
///
/// ```swift
/// TextView {
///     "Hi there,"
///     LineBreak()
///     "RichText is a SwiftUI framework that provides better Text experience."
/// }
/// .font(.body)
/// .lineSpacing(8)
/// .lineLimit(2)
/// .truncationMode(.tail)
/// ```
public struct TextView: View {
    /// A raw text content directly from the view's input
    ///
    /// To keep the view layout consistent, we merge view attachments, since the result builder always creates new ones
    /// which would otherwise reset the text engine’s layout and lead to incorrect layout results.
    ///
    /// To get merged result, use `content`.
    private var rawContent: TextContent
    @State private var content = TextContent()
    
    @State private var attachments: [InlineHostingAttachment] = []
    @Environment(\.fontResolutionContext) private var fontResolutionContext
    
    /// Creates an instance with the given closure to build text content.
    ///
    /// - Parameter content: A ``TextContent`` that stores all fragments of the text.
    public init(@TextContentBuilder content: () -> TextContent) {
        self.rawContent = content()
    }
    
    /// Creates an instance with the given localized content identified by a key.
    ///
    /// - parameters:
    ///     - key: The key for the localized string resource.
    ///     - tableName: The name of the localization lookup table.
    ///     - bundle: The bundle containing the localization resource.
    ///     - comment: The comment describing the context for translators.
    ///
    /// This initializer mirrors the behavior of `SwiftUI.Text(_:tableName:bundle:comment:)`, supporting:
    /// - Automatic string localization
    /// - Inline markdown parsing and styling
    ///
    /// > important:
    /// >
    /// > This initializer does NOT support view embedding. If you want to embed a view, use ``init(content:)`` instead.
    /// >
    /// > `TextView` doesn’t render all styling possible in Markdown -- just like `SwiftUI.Text` -- breaks, style of any paragraph- or block-based formatting are not supported.
    public init(
        _ key: LocalizedStringKey,
        tableName: String? = nil,
        bundle: Bundle? = nil,
        comment: StaticString? = nil
    ) {
        let localized = String(
            localized: LocalizedStringResource(
                String.LocalizationValue(
                    key.key ?? ""
                ),
                table: tableName,
                bundle: bundle ?? .main,
                comment: comment
            )
        )
        
        let fragement: TextContent.Fragment
        do {
            fragement = try .attributedString(
                AttributedString(
                    markdown: localized,
                    options: AttributedString.MarkdownParsingOptions(
                        allowsExtendedAttributes: true,
                        interpretedSyntax: .inlineOnlyPreservingWhitespace,
                        failurePolicy: .returnPartiallyParsedIfPossible
                    )
                )
            )
        } catch {
            fragement = .string(localized)
        }
        self.rawContent = TextContent(fragement)
    }
    
    /// Creates an instance with the given string literal without localization.
    ///
    /// - parameter content: A string literial to display without localization.
    ///
    /// This initializer aligns with the `SwiftUI.Text(verbatim:)` initializer.
    ///
    /// > important:
    /// >
    /// > This initializer does NOT support view embedding. If you want to embed a view, use ``init(content:)`` instead.
    public init(verbatim content: String) {
        self.rawContent = TextContent(.string(content))
    }
    
    public var body: some View {
        _textView
            .onChange(of: rawContent, initial: true) {
                var existingAttachmentsByID: [InlineHostingAttachment.ID : InlineHostingAttachment] = [:]
                for attachment in self.attachments {
                    existingAttachmentsByID[attachment.id] = attachment
                }
                let textContent = rawContent
                // Reuse existing attachment states.
                for case let .view(attachment) in textContent.fragments {
                    if let existingState = existingAttachmentsByID[attachment.id]?.state {
                        attachment.state = existingState
                    }
                }
                
                self.content = textContent
                self.attachments = textContent.attachments
            }
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    ForEach(attachments) { attachment in
                        attachment.view
                            .onGeometryChange(for: CGSize.self, of: \.size) { size in
                                attachment.state.size = size
                            }
                            .offset(
                                x: attachment.state.origin?.x ?? 0,
                                y: attachment.state.origin?.y ?? 0
                            )
                            .opacity(attachment.state.origin == nil ? 0 : 1)
                    }
                }
            }
    }
    
    private var _textView: some View {
        #if canImport(AppKit)
        _TextView_AppKit(content: content)
        #elseif canImport(UIKit)
        _TextView_UIKit(content: content)
        #else
        ContentUnavailableView(
            "Content Not Available",
            systemImage: "exclamationmark.triangle"
        )
        #endif
    }
}

// MARK: - Auxiliary

fileprivate extension TextContent {
    var attachments: [InlineHostingAttachment] {
        fragments.compactMap { fragment in
            if case .view(let attachment) = fragment {
                return attachment
            }
            return nil
        }
    }
}

extension AttributedString {
    var nsAttributedString: NSAttributedString {
        get throws {
            let result = NSMutableAttributedString()

            for run in runs {
                let converted = try NSMutableAttributedString(
                    AttributedString(self[run.range]),
                    including: \.richText
                )
                let range = NSRange(location: 0, length: converted.length)
                
                if let attachment = run.inlineHostingAttachment {
                    converted.addAttribute(
                        .attachment,
                        value: attachment,
                        range: range
                    )
                }

                result.append(converted)
            }

            return NSAttributedString(attributedString: result)
        }
    }
}
