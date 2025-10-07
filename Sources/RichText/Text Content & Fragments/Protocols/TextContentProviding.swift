//
//  TextContentProviding.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/7.
//

public protocol TextContentProviding {
    @TextContentBuilder
    var textContent: TextContent { get }
}

public protocol InterFragment : TextContentProviding { }
