//
//  TextViewContentBuilder.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/5.
//

import SwiftUI

@resultBuilder
public enum TextViewContentBuilder {
    public static func buildBlock() -> TextViewContent {
        TextViewContent()
    }
    
    public static func buildBlock(_ components: TextViewContent...) -> TextViewContent {
        components.reduce(TextViewContent(), +)
    }

    public static func buildOptional(_ component: TextViewContent?) -> TextViewContent {
        component ?? TextViewContent()
    }

    public static func buildEither(first component: TextViewContent) -> TextViewContent {
        component
    }

    public static func buildEither(second component: TextViewContent) -> TextViewContent {
        component
    }

    public static func buildArray(_ components: [TextViewContent]) -> TextViewContent {
        components.reduce(TextViewContent(), +)
    }

    // MARK: Expressions
    
    public static func buildExpression(_ expression: TextViewContent) -> TextViewContent {
        expression
    }

    public static func buildExpression(_ expression: String) -> TextViewContent {
        TextViewContent(.string(expression))
    }

    public static func buildExpression(_ expression: AttributedString) -> TextViewContent {
        TextViewContent(.attributedString(expression))
    }

    @MainActor
    public static func buildExpression<Content: View>(_ expression: Content) -> TextViewContent {
        TextViewContent(.attachment(InlineHostingAttachment(expression)))
    }
}
