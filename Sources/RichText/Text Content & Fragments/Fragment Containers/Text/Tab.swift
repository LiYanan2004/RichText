//
//  Tab.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/7.
//

import Foundation

/// A tab fragment.
///
/// Inserts one or more tab characters between text fragments.
public struct Tab: InterFragment {
    var count: Int

    /// Creates a tab fragment with the given number of tab characters.
    public init(_ count: Int = 1) {
        self.count = count
    }

    /// Produces a ``TextContent`` value that contains the configured tabs.
    public var textContent: TextContent {
        TextContent(
            .string(
                [String](repeating: "\t", count: count).joined()
            )
        )
    }
}

extension InterFragment where Self == Tab {
    /// A single tab fragment,
    static var tab: Tab { .init() }

    /// A tab fragment that contains the specified numbers of tab (aka. '\t') characters.
    static func tab(_ count: Int) -> Tab {
        .init(count)
    }
}
