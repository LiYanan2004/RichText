//
//  TextContentProviding.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/7.
//

/// A view that represents part of your ``TextContent``.
public protocol TextContentProviding {
    @MainActor
    @TextContentBuilder
    var textContent: TextContent { get }
}

/// A marker protocol for inter-fragments, e.g. ``Space``, ``Tab`` and ``LineBreak``.
public protocol InterFragment : TextContentProviding { }
