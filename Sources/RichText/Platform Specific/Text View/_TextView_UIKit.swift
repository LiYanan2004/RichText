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
        
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        
        if #available(iOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            textView.font = Font.default
                .resolve(in: context.environment.fontResolutionContext)
                .ctFont as UIFont
        }
        
        return textView
    }
    
    func updateUIView(_ textView: InlineAttachmentTextView, context: Context) {
        textView._attributedString = attributedString
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
