//
//  LineBreak.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/7.
//

import Foundation

/// A line break (or hard break) text fragment.
///
/// Inserts one or more newline characters between text fragments.
public struct LineBreak: InterFragment {
    var count: Int

    /// Creates a line break fragment with the given number of newline characters.
    public init(_ count: Int = 1) {
        self.count = count
    }

    /// Produces a ``TextContent`` value that contains the configured line breaks.
    public var textContent: TextContent {
        TextContent(
            .string(
                [String](repeating: "\n", count: count).joined()
            )
        )
    }
}

extension InterFragment where Self == LineBreak {
    /// A single line break fragment.
    static public var lineBreak: LineBreak { .init() }

    /// A line break fragment that contains the specified numbers of newline characters.
    static public func lineBreak(_ count: Int) -> LineBreak {
        .init(count)
    }
}
