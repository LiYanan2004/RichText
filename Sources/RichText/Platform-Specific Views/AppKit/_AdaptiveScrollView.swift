//
//  _AdaptiveScrollView.swift
//  RichText
//
//  Created by Yanan Li on 2025/8/24.
//

#if canImport(AppKit)
import AppKit

/// An `NSScrollView` that scrolls normally or fits content when nested.
final class _AdaptiveScrollView: NSScrollView {
    private var isEmbeddedInScrollView: Bool {
        enclosingScrollView != nil
    }
    
    override var intrinsicContentSize: NSSize {
        if isEmbeddedInScrollView, let documentView {
            return documentView.intrinsicContentSize
        }
        return super.intrinsicContentSize
    }
    
    override func layout() {
        super.layout()
        invalidateIntrinsicContentSize()
    }
    
    override func scrollWheel(with event: NSEvent) {
        if isEmbeddedInScrollView {
            nextResponder?.scrollWheel(with: event)
        } else {
            super.scrollWheel(with: event)
        }
    }
}
#endif
