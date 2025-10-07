//
//  LineBreak.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/7.
//

import Foundation

public struct LineBreak: InterFragment {
    var count: Int

    public init(_ count: Int = 1) {
        self.count = count
    }

    public var textContent: TextContent {
        TextContent(
            .string(
                [String](repeating: "\n", count: count).joined()
            )
        )
    }
}

extension InterFragment where Self == LineBreak {
    static var lineBreak: LineBreak { .init() }
   
    static func lineBreak(_ count: Int) -> LineBreak {
        .init(count)
    }
}
