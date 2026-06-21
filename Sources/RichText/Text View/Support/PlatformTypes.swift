//
//  PlatformView.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/4.
//

import SwiftUI

#if os(iOS) || os(tvOS)
@_documentation(visibility: internal)
public typealias PlatformView = UIView
@_documentation(visibility: internal)
public typealias PlatformImage = UIImage
@_documentation(visibility: internal)
public typealias PlatformFont = UIFont
@_documentation(visibility: internal)
public typealias PlatformHostingView = UIView
@_documentation(visibility: internal)
public typealias PlatformTextView = UITextView
#elseif os(macOS)
@_documentation(visibility: internal)
public typealias PlatformView = NSView
@_documentation(visibility: internal)
public typealias PlatformImage = NSImage
@_documentation(visibility: internal)
public typealias PlatformFont = NSFont
@_documentation(visibility: internal)
public typealias PlatformHostingView = NSHostingView<AnyView>
@_documentation(visibility: internal)
public typealias PlatformTextView = NSTextView
#endif


