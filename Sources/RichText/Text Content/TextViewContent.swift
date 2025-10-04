//
//  TextViewContent.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/2.
//

import SwiftUI

public struct TextViewContent: Hashable {
    public enum Fragment: Hashable {
        case string(String)
        case attributedString(AttributedString)
        case attachment(InlineHostingAttachment)

        @MainActor
        func asAttributedString() -> AttributedString {
            switch self {
            case .string(let string):
                return AttributedString(string)
            case .attributedString(let attributedString):
                return attributedString
            case .attachment(let attachment):
                let container = AttributeContainer().inlineHostingAttachment(attachment)
                return AttributedString("\u{FFFC}", attributes: container)
            }
        }
    }

    public var fragments: [Fragment]
    
    public init(_ fragments: Fragment...) {
        self.fragments = fragments
    }
    
    public init(_ fragments: [Fragment]) {
        self.fragments = fragments
    }

    static public func + (lhs: TextViewContent, rhs: TextViewContent) -> TextViewContent {
        TextViewContent(lhs.fragments + rhs.fragments)
    }
    
    public static func += (lhs: inout TextViewContent, rhs: TextViewContent) {
        lhs.fragments += rhs.fragments
    }

    @MainActor
    var attributedString: AttributedString {
        fragments.reduce(into: AttributedString()) { result, fragment in
            result += fragment.asAttributedString()
        }
    }
}
