//
//  _TextView_UIKit.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/4.
//

#if canImport(UIKit)
import SwiftUI

struct _TextView_UIKit: UIViewRepresentable {
    var content: TextContent
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIView(context: Context) -> InlineAttachmentTextView {
        let textView = InlineAttachmentTextView(frame: .zero)
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        
        textView.textContainer.lineFragmentPadding = .zero
        textView.textContainerInset = .zero
        textView.contentInset = .zero
        
        return textView
    }
    
    func updateUIView(_ textView: InlineAttachmentTextView, context: Context) {
        TextAttributeConverter.mergeEnvironmentValueIntoTextView(
            textView,
            context: context
        )
        textView._attributedString = content.attributedString(context: context)
    }
    
    // For UITextView, it comes with a UIScrollView
    //
    // Since we have override `intrinsticContentSize` and disabled scrolling, it should act like a normal UIView
    //
    // For better control of SwiftUI View size when place it inside a ScrollView, we use `sizeThatFits` to explicitly calculate a size in SwiftUI.
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: InlineAttachmentTextView,
        context: Context
    ) -> CGSize? {
        uiView.sizeThatFits(
            proposal.replacingUnspecifiedDimensions(
                by: CGSize(
                    width: UIView.noIntrinsicMetric,
                    height: UIView.noIntrinsicMetric
                )
            )
        )
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
#endif
