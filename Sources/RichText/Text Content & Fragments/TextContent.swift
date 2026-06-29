//
//  TextContent.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/2.
//

import SwiftUI

/// A value that stores the fragments that make up a ``TextView``.
///
/// ``TextContent`` is typically produced by the ``TextContentBuilder`` result builder. You can also construct an instance manually to compose fragments or concatenate multiple values.
public struct TextContent {
    /// An individual piece of content that can be stored inside ``TextContent``.
    public enum Fragment {
        /// A plain string fragment.
        case string(String)
        /// An attributed string fragment.
        case attributedString(AttributedString)
        /// An inline SwiftUI view attachment.
        case view(InlineHostingAttachment)
        
        public func asAttributedString() -> AttributedString {
            switch self {
                case .string(let string):
                    return AttributedString(string)
                case .attributedString(let attributedString):
                    return attributedString
                case .view(let attachment):
                    let container = try! AttributeContainer(
                        [.inlineHostingAttachment : attachment],
                        including: \.richText
                    )
                    return AttributedString("\u{FFFC}", attributes: container)
            }
        }
    }
    
    /// An ordered array of fragments within the storage.
    public var fragments: [Fragment]
    
    /// Creates an instance from a variadic list of fragments.
    public init(_ fragments: Fragment...) {
        self.fragments = fragments
    }
    
    public init(@TextContentBuilder fragments: () -> TextContent) {
        self = fragments()
    }
    
    /// Creates an instance from an array of fragments.
    public init(_ fragments: [Fragment]) {
        self.fragments = fragments
    }
    
    /// Concatenates two ``TextContent`` values.
    static public func + (lhs: TextContent, rhs: TextContent) -> TextContent {
        TextContent(lhs.fragments + rhs.fragments)
    }
    
    /// Merges fragments from both of the side (left-hand-side first) and store them into left-hand-side variable.
    public static func += (lhs: inout TextContent, rhs: TextContent) {
        lhs.fragments += rhs.fragments
    }
    
    /// Returns an attributed string that contains all fragments.
    ///
    /// `SwiftUI.Font` values are resolved as `UIFont` / `NSFont`, depending on the target platform, **on OS 26 and later**.
    ///
    /// On earlier systems, use `PlatformFont` rather than `SwiftUI.Font` when creating `AttributedString`
    /// since the text view is backed by platform view, `SwiftUI.Font` is not respected.
    ///
    /// - Parameter environmentValues: The environment values used to render the text.
    public func attributedString(environmentValues: EnvironmentValues) -> AttributedString {
        attributedString(
            configuration: TextViewRenderConfiguration(environmentValues: environmentValues)
        )
    }

    func attributedString(configuration: TextViewRenderConfiguration) -> AttributedString {
        var attributedString = fragments.reduce(into: AttributedString()) { result, fragment in
            result += fragment.asAttributedString()
        }
        
        attributedString = TextAttributeConverter.mergingEnvironmentValuesIntoAttributedString(
            attributedString,
            configuration: configuration
        )
        attributedString = TextAttributeConverter.convertingAndMergingSwiftUIAttributesIntoAttributedString(
            attributedString,
            configuration: configuration
        )
        
        attributedString = TextAttributeConverter.resolveInlinePresentationIntent(in: attributedString)
        
        return attributedString
    }
}
