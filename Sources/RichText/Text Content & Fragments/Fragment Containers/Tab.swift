//
//  Tab.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/7.
//

import Foundation

public struct Tab: InterFragment {
    var count: Int

    public init(_ count: Int = 1) {
        self.count = count
    }

    public var textContent: TextViewContent {
        TextViewContent(
            .string(
                [String](repeating: "\t", count: count).joined()
            )
        )
    }
}

extension InterFragment where Self == Tab {
    static var tab: Tab { .init() }
   
    static func tab(_ count: Int) -> Tab {
        .init(count)
    }
}
