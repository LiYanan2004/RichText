//
//  Paragraph.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/7.
//

import SwiftUI

public struct Paragraph: CustomTextContentConvertible {
    let content: () -> TextViewContent

    public init(@TextViewContentBuilder content: @escaping () -> TextViewContent) {
        self.content = content
    }

    public var textContent: TextViewContent {
        var content = content()
        content += TextViewContent(.string("\n"))
        return content
    }
}
