//
//  type.swift
//  RichText
//
//  Created by Yanan Li on 2026/5/5.
//

import SwiftUI
import Introspection

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
