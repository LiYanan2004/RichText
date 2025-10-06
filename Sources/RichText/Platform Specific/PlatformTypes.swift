//
//  PlatformView.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/4.
//

import SwiftUI

#if os(iOS) || os(tvOS)
public typealias PlatformView = UIView
public typealias PlatformImage = UIImage
public typealias PlatformFont = UIFont
public typealias PlatformHostingView = UIView
public typealias PlatformTextView = UITextView
#elseif os(macOS)
public typealias PlatformView = NSView
public typealias PlatformImage = NSImage
public typealias PlatformFont = NSFont
public typealias PlatformHostingView = NSHostingView<AnyView>
public typealias PlatformTextView = NSTextView
#endif


