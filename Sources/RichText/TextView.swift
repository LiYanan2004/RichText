//
//  TextView.swift
//  RichText
//
//  Created by Yanan Li on 2025/8/24.
//

import SwiftUI
import Introspection

/// A rich text container that renders plain strings, attributed strings, and
/// inline SwiftUI views together while offers the same text selection experience.
///
/// You declare the text content by using:
/// - `StringProtocol`-conforming types, such as `String`, `Substring`, etc., for plain-text fragment
/// - `Foundation.AttributedString` for attributed string (or rich text) fragment
/// - `SwiftUI.View` for platform view fragment (without replacement text)
/// - ``InlineView`` for platform view fragment (with optional replacement)
///     - This would have the same effect as previous one, if you choose not providing a replacement text.
///
/// ```swift
/// TextView {
///     "Tap the "
///     InlineView("button") { // Copy the button will get text "button"
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
/// ### Additional notes on custom view embedding
///
/// **Providing an explicit ``id(_:)`` for each view is recommended**, as it helps reduce unnecessary re-layouts and would help improve performance.
///
/// Plus, if your view owns a state (e.g. you're using `@State`, `@StateObject`, etc. within the view), the identity is also used to preserve the state of a view.
///
/// For more information, check out ``InlineHostingAttachment/id``
///
/// ### SwiftUI View modifiers
///
/// Most of the text-styling view modifiers should work seamlessly with `TextView`.
///
/// ```swift
/// TextView {
///     "Hi there,"
///     LineBreak()
///     "RichText is a SwiftUI framework that provides better Text experience."
/// }
/// .font(.body) // only works on OS 26+
/// .lineSpacing(8)
/// .lineLimit(2)
/// .truncationMode(.tail)
/// ```
///
/// > note:
/// > `.font(_:)` modifier only takes effect on OS 26 and newer platforms. To ensure the consistency, use ``font(_:)-(PlatformFont?)`` instead -- pass in `PlatformFont`.
///
/// > note:
/// > Text modifiers -- such as `baselineOffset(_:)`, `kerning(_:)`, `bold(_:)`, etc. -- are not available since SwiftUI does not expose environment values for those properties. For these use cases, use `AttributedString` instead.
public struct TextView: View {
    public var content: TextContent
    
    @State private var attachments: [InlineHostingAttachment] = []
    @Environment(\.fontResolutionContext) private var fontResolutionContext
    
    /// Creates an instance with the given closure to build text content.
    ///
    /// - Parameter content: A ``TextContent`` that stores all fragments of the text.
    public init(@TextContentBuilder content: () -> TextContent) {
        self.content = content()
    }
    
    public var body: some View {
        _textView
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    ForEach(content.attachments) { attachment in
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
            .clipped()
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

// MARK: - Initializers

extension TextView {
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
            localized: String.LocalizationValue(
                ResolvedLocalizedStringKey(key).localizedString(
                    tableName: tableName,
                    bundle: bundle,
                    comment: comment
                ) ?? ""
            ),
            table: tableName,
            bundle: bundle ?? .main,
            comment: comment
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
        self.content = TextContent(fragement)
    }
    
    /// Creates an instance with the given string literal without localization.
    ///
    /// - parameter content: A string literial to display, without localization.
    ///
    /// This initializer aligns with the `SwiftUI.Text(verbatim:)` initializer.
    ///
    /// > important:
    /// >
    /// > This initializer does NOT support view embedding. If you want to embed a view, use ``init(content:)`` instead.
    public init(verbatim content: String) {
        self.content = TextContent(.string(content))
    }
    
    /// Creates an instance from a stored string without localization.
    ///
    /// - Parameter content: A string value that conforms to `StringProtocol`.
    ///
    /// This initializer accepts any string protocol type and displays its value as-is, without localization.
    /// If you pass in a string literal, ``init(_:tableName:bundle:comment:)`` will be called instead of this one.
    @_disfavoredOverload public init<S: StringProtocol>(_ content: S) {
        self.init(verbatim: String(content))
    }
    
    /// Creates an instance with the given localized string resource, resolving it at runtime.
    ///
    /// - Parameter localizedStringResource: The localized string resource to display.
    ///
    /// If you pass in a string literal, ``init(_:tableName:bundle:comment:)`` will be called instead of this one.
    @_disfavoredOverload public init(_ localizedStringResource: LocalizedStringResource) {
        self.init(verbatim: String(localized: localizedStringResource))
    }
    
    /// Creates an instance with the given `AttributedString`.
    ///
    /// - Parameter attributedString: The attributed string to display.
    ///
    /// For simple Markdown styled text, you can use ``init(_:tableName:bundle:comment:)``directly.
    ///
    /// > important:
    /// >
    /// > This initializer does NOT support embedded views. For mixed content (text and views), use ``init(content:)`` instead.
    @_disfavoredOverload public init(_ attributedString: AttributedString) {
        self.content = TextContent(.attributedString(attributedString))
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
