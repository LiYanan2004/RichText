//
//  Space.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/7.
//

import Foundation

public struct Space: InterFragment {
    var count: Int

    public init(_ count: Int = 1) {
        self.count = count
    }

    public var textContent: TextViewContent {
        TextViewContent(
            .string(
                [String](repeating: " ", count: count).joined()
            )
        )
    }
}

extension InterFragment where Self == Space {
    static var space: Space { .init() }
   
    static func space(_ count: Int) -> Space {
        .init(count)
    }
}
