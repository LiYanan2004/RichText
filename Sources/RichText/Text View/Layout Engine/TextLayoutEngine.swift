//
//  TextLayoutEngine.swift
//  RichText
//
//  Created by Yanan Li on 2026/6/20.
//

import Foundation

/// A type that selects the text layout engine used by ``TextView``.
public protocol TextLayoutEngine {
    /// A Boolean value that indicates whether the text layout engine uses TextKit 2.
    static var usesTextLayoutManager: Bool { get }
}

// MARK: - TextKit 1

/// A text layout engine that uses TextKit 1.
public struct TextKit1TextLayoutEngine: TextLayoutEngine {
    public static let usesTextLayoutManager = false

    init() {}
}

extension TextLayoutEngine where Self == TextKit1TextLayoutEngine {
    /// The TextKit 1 text layout engine.
    public static var textKit1: TextKit1TextLayoutEngine { .init() }
}

// MARK: - TextKit 2

/// A text layout engine that uses TextKit 2.
public struct TextKit2TextLayoutEngine: TextLayoutEngine {
    public static let usesTextLayoutManager = true

    init() {}
}

extension TextLayoutEngine where Self == TextKit2TextLayoutEngine {
    /// The TextKit 2 text layout engine.
    public static var textKit2: TextKit2TextLayoutEngine { .init() }
}
