//
//  _TextView_AppKit.swift
//  RichText
//
//  Created by Yanan Li on 2025/8/24.
//

#if canImport(AppKit)
import SwiftUI

struct _TextView_AppKit: NSViewRepresentable {
    var content: TextContent
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeNSView(context: Context) -> InlineAttachmentTextView {
        let textView = InlineAttachmentTextView(
            usingTextLayoutManager: context.environment.usesTextLayoutManager
        )
        textView.drawsBackground = false
        textView.delegate = context.coordinator.self
        
        // Behavior
        textView.isEditable = false
        textView.usesAdaptiveColorMappingForDarkAppearance = true
        
        // Sizing
        textView.textContainerInset = .zero
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.isVerticallyResizable = false
        textView.isHorizontallyResizable = false
        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = true
            textContainer.heightTracksTextView = false
            textContainer.lineFragmentPadding = .zero
        }
        
        return textView
    }
    
    func updateNSView(_ textView: InlineAttachmentTextView, context: Context) {
        context.coordinator.parent = self

        let configuration = TextViewRenderConfiguration(context: context)
        TextAttributeConverter.mergeRenderConfigurationIntoTextView(
            textView,
            configuration: configuration
        )
        textView.applyAttributedStringPreservingAttachments(
            content.attributedString(configuration: configuration)
        )
    }
    
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: _TextView_AppKit

        init(_ parent: _TextView_AppKit) {
            self.parent = parent
        }
    }
}
#endif
