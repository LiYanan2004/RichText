//
//  Space.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/7.
//

import Foundation

/// A whitespace fragment.
///
/// Inserts one or more whitespace characters between text fragments.
public struct Space: InterFragment {
    var count: Int

    /// Creates a space fragment with the given number of space characters.
    public init(_ count: Int = 1) {
        self.count = count
    }

    /// Produces a ``TextContent`` value that contains the configured spaces.
    public var textContent: TextContent {
        TextContent(
            .string(
                [String](repeating: " ", count: count).joined()
            )
        )
    }
}

extension InterFragment where Self == Space {
    /// A single space fragment.
    static public var space: Space { .init() }

    /// A space fragment that contains the specified numbers of whitespace characters.
    static public func space(_ count: Int) -> Space {
        .init(count)
    }
}
