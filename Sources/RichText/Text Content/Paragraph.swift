//
//  Paragraph.swift
//  RichText
//
//  Created by OpenAI's ChatGPT on 2024/3/7.
//

import SwiftUI

public struct Paragraph: CustomTextContentConvertible {
    private let content: TextViewContent

    public init(@TextViewContentBuilder content: () -> TextViewContent) {
        var content = content()
        content += TextViewContent(.string("\n"))
        self.content = content
    }

    public var textContent: TextViewContent {
        content
    }
}
