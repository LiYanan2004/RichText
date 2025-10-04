//
//  _TextView_UIKit.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/4.
//

#if canImport(UIKit)
import SwiftUI

struct _TextView_UIKit: UIViewRepresentable {
    var attributedString: AttributedString
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIView(context: Context) -> InlineAttachmentTextView {
        let textView = InlineAttachmentTextView(frame: .zero)
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        textView.textColor = .label
        
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        
        return textView
    }
    
    func updateUIView(_ textView: InlineAttachmentTextView, context: Context) {
        textView.attributedContent = attributedString
    }
    
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: _TextView_UIKit
        weak var textView: InlineAttachmentTextView?
        var editMenuInteraction: UIEditMenuInteraction?
        
        init(_ parent: _TextView_UIKit) {
            self.parent = parent
        }
        
    }
}

private extension AttributedString {
    var hasExplicitForegroundColor: Bool {
        for run in runs { if run.foregroundColor != nil { return true } }
        return false
    }
}
#endif
