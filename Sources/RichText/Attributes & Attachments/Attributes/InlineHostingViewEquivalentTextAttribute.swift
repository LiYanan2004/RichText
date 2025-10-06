//
//  InlineHostingViewEquivalentTextAttribute.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/7.
//

import Foundation

extension AttributeScopes.RichTextAttributes {
    struct InlineHostingViewEquivalentTextAttribute: AttributedStringKey {
        typealias Value = String?
        static let name: String = "InlineHostingViewEquivalentText"
    }
}

extension NSAttributedString.Key {
    static let inlineHostingViewEquivalentText = NSAttributedString.Key(
        AttributeScopes.RichTextAttributes.InlineHostingViewEquivalentTextAttribute.name
    )
}
