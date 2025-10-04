//
//  _TextView_AppKit.swift
//  RichText
//
//  Created by Yanan Li on 2025/8/24.
//

import SwiftUI

#if canImport(AppKit)
struct _TextView_AppKit: NSViewRepresentable {
    var attributedString: AttributedString
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeNSView(context: Context) -> InlineAttachmentTextView {
        let textView = InlineAttachmentTextView(frame: .zero)
        textView.drawsBackground = false
        textView.delegate = context.coordinator.self
        
        // Behavior
        textView.isEditable = false
        textView.usesAdaptiveColorMappingForDarkAppearance = true
        
        // Sizing
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = false
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = true
        
        return textView
    }
    
    func updateNSView(_ textView: InlineAttachmentTextView, context: Context) {
        textView.attributedContent = attributedString
    }
    
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: _TextView_AppKit
        init(_ parent: _TextView_AppKit) {
            self.parent = parent
        }
    }
}
#endif
