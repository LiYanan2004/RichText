//
//  InlineHostingAttachmentAttribute.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/3.
//

import Foundation

extension AttributeScopes.RichTextAttributes {
    struct InlineHostingAttachmentAttribute: AttributedStringKey {
        typealias Value = InlineHostingAttachment
        static let name: String = "InlineHostingAttachment"
    }
}

extension NSAttributedString.Key {
    static let inlineHostingAttachmentAttribute = NSAttributedString.Key(
        AttributeScopes.RichTextAttributes.InlineHostingAttachmentAttribute.name
    )
}
