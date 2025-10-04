//
//  File.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/4.
//

import SwiftUI

extension InlineAttachmentTextView {
    func invalidateTextLayout(at range: NSRange) {
        guard let textLayoutManager,
              let textContentManager = textLayoutManager.textContentManager else {
            return
        }
    
        let textRange = NSTextRange(range, textContentManager: textContentManager)
        guard let textRange else { return }
        
        textLayoutManager.invalidateLayout(for: textRange)
        textLayoutManager.ensureLayout(for: textRange)
        
        _invalidateTextLayout()
    }
    
    private func _invalidateTextLayout() {
        #if canImport(AppKit)
        needsLayout = true
        setNeedsDisplay(bounds)
        #elseif canImport(UIKit)
        setNeedsLayout()
        setNeedsDisplay()
        #endif
    }
    
    #if canImport(AppKit)
    override func layout() {
        super.layout()
        invalidateIntrinsicContentSize()
        updateAttachmentOrigins()
    }
    #elseif canImport(UIKit)
    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
        updateAttachmentOrigins()
    }
    #endif
}

// MARK: - Auxiliary

extension NSTextRange {
    convenience init?(_ nsRange: NSRange, textContentManager: NSTextContentManager) {
        let documentStart = textContentManager.documentRange.location
        let startLocation = textContentManager.location(
            documentStart,
            offsetBy: nsRange.location
        )
        guard let startLocation else { return nil }
        
        let endLocation = textContentManager.location(
            documentStart,
            offsetBy: nsRange.location + nsRange.length
        )
        self.init(location: startLocation, end: endLocation)
    }
}

