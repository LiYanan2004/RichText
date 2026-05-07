//
//  InlineAttachmentTextView.swift
//  RichText
//
//  Created by Yanan Li on 2025/8/24.
//

import SwiftUI

final class InlineAttachmentTextView: PlatformTextView {
    private var ownedTextContentStorage: NSTextContentStorage?
    private var _attributedString: AttributedString = .init() {
        didSet {
            setAttributedString(_attributedString)
        }
    }
    private var inlineAttachmentViews: [ObjectIdentifier: PlatformView] = [:]
    
    var textContentManager: NSTextContentManager? {
        textLayoutManager?.textContentManager
    }
    
    var _textContentStorage: NSTextContentStorage? {
        textContentManager as? NSTextContentStorage
    }
    
    override var intrinsicContentSize: CGSize {
        #if canImport(AppKit)
        // TODO: Is there any efficient way to calculate the height of the view?
        CGSize(width: PlatformView.noIntrinsicMetric, height: _measuredContentHeight)
        #else
        CGSize(width: PlatformView.noIntrinsicMetric, height: PlatformView.noIntrinsicMetric)
        #endif
    }
    
    #if canImport(AppKit)
    // FIXME: This only works for "Copy" and "Search with Google".
    // Lookup, Translate, Share are using original strings
    override func attributedSubstring(
        forProposedRange range: NSRange,
        actualRange: NSRangePointer?
    ) -> NSAttributedString? {
        guard let original = super.attributedSubstring(
            forProposedRange: range,
            actualRange: actualRange
        ) else { return nil }

        return replaceAttachmentWithEquivalentText(
            in: original
        )
    }
    #else
    override func attributedText(in range: UITextRange) -> NSAttributedString {
        replaceAttachmentWithEquivalentText(
            in: super.attributedText(in: range)
        )
    }

    override func text(in range: UITextRange) -> String? {
        return attributedText(in: range).string
    }
    
    // TODO: It would be better to have a way to directly modify the copying item for each attachment. `NSItemProviderWriting` is not working here.
    override func copy(_ sender: Any?) {
        guard let documentRange = textRange(from: beginningOfDocument, to: endOfDocument) else {
            super.copy(sender)
            return
        }
        
        let attributedString = attributedText(in: documentRange)
        UIPasteboard.general.setObjects([attributedString])
    }
    #endif
    
    private func replaceAttachmentWithEquivalentText(
        in attributedString: NSAttributedString
    ) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributedString)
        mutable.enumerateAttribute(
            .inlineHostingAttachment,
            in: NSRange(location: 0, length: mutable.length),
            options: []
        ) { attachment, subrange, _ in
            guard let attachment = attachment as? InlineHostingAttachment,
                  let replacement = attachment.replacement else { return }
            
            let nsAttrString: NSAttributedString
            do {
                let _nsAttrString = try NSMutableAttributedString(
                    attributedString: replacement.nsAttributedString
                )
                let range = NSRange(location: 0, length: _nsAttrString.length)
                _nsAttrString._fixForgroundColorIfNecessary(in: range)
                _nsAttrString._fixFont(self.font, in: range)
                nsAttrString = _nsAttrString
            } catch {
                nsAttrString = NSAttributedString(replacement)
            }
            
            mutable.replaceCharacters(in: subrange, with: nsAttrString)
        }
        return mutable
    }
    
    private func setAttributedString(_ attributedString: AttributedString) {
        do {
            let attributed = try NSMutableAttributedString(
                attributedString: attributedString.nsAttributedString
            )
            let range = NSRange(location: 0, length: attributed.length)
            
            attributed._fixForgroundColorIfNecessary(in: range)
            attributed._fixFont(self.font, in: range)
            
            _textStorage?.beginEditing()
            
            if let textStorage = _textContentStorage?.textStorage {
                textStorage.setAttributedString(attributed)
            } else if let textContentStorage = _textContentStorage {
                textContentStorage.attributedString = attributed
            } else if let textLayoutManager {
                textLayoutManager.replaceContents(in: textLayoutManager.documentRange, with: attributed)
            } else {
                _textStorage?.setAttributedString(attributed)
            }
            
            _textStorage?.endEditing()
            
            if let textLayoutManager {
                textLayoutManager.invalidateLayout(for: textLayoutManager.documentRange)
                textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)
                textLayoutManager.textViewportLayoutController.layoutViewport()
            }
            
            _invalidateTextLayout()
        } catch {
            // TODO: use logger.
            print("Failed to build attributed string: \(error)")
        }
    }
    
    func applyAttributedString(_ attributedString: AttributedString) {
        updateInlineAttachmentsIfPossible(
            newAttrString: attributedString
        )
    }
}

// MARK: - Helpers

extension InlineAttachmentTextView {
    static func textViewUsingTextLayoutManager() -> InlineAttachmentTextView {
        let textContentStorage = NSTextContentStorage()
        let textLayoutManager = NSTextLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        
        textContentStorage.addTextLayoutManager(textLayoutManager)
        textLayoutManager.textContainer = textContainer
        
        let textView = InlineAttachmentTextView(
            frame: .zero,
            textContainer: textContainer
        )
        textView.ownedTextContentStorage = textContentStorage
        return textView
    }
    
    private func updateInlineAttachmentsIfPossible(newAttrString: AttributedString) {
        var mergedAttributedString = newAttrString
        
        for newRun in mergedAttributedString.runs {
            guard let attachment = newRun[keyPath: \.inlineHostingAttachment],
                  let oldAttachment = currentAttachment(id: attachment.id)
            else { continue }
            
            let didChangeIntrinsicContentSize = MainActor.assumeIsolated {
                oldAttachment.updateContent(from: attachment)
            }
            if didChangeIntrinsicContentSize {
                _textStorage?.invalidateAttributes(in: NSRange(newRun.range, in: newAttrString))
            }
            
            mergedAttributedString[newRun.range].setAttributes(
                newRun.attributes.merging(
                    AttributeContainer().inlineHostingAttachment(oldAttachment),
                    mergePolicy: .keepNew
                )
            )
        }
        
        self._attributedString = mergedAttributedString
    }
    
    private func currentAttachment(id: AnyHashable) -> InlineHostingAttachment? {
        guard let textStorage = _textContentStorage?.textStorage ?? _textStorage else {
            return nil
        }
        
        let fullRange = NSRange(location: 0, length: textStorage.length)
        var attachment: InlineHostingAttachment?
        textStorage.enumerateAttribute(.attachment, in: fullRange) { value, range, stop in
            guard let currentAttachment = value as? InlineHostingAttachment,
                  currentAttachment.id == id else {
                return
            }
            
            attachment = currentAttachment
            stop.pointee = true
        }
        
        return attachment
    }
}

extension InlineAttachmentTextView {
    var textContainerOffset: CGPoint {
        #if canImport(AppKit)
        return textContainerOrigin
        #elseif canImport(UIKit)
        return CGPoint(
            x: textContainerInset.left,
            y: textContainerInset.top
        )
        #else
        return .zero
        #endif
    }
    
    private var _measuredContentHeight: CGFloat {
        guard let textLayoutManager else { return bounds.height }
        
        textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)

        var maxY: CGFloat = 0
        textLayoutManager.enumerateTextSegments(
            in: textLayoutManager.documentRange,
            type: .standard,
            options: [.rangeNotRequired]
        ) { _, segmentFrame, _, _ in
            if segmentFrame.maxY > maxY { maxY = segmentFrame.maxY }
            return true
        }
        
        let totalHeight = maxY + textContainerOffset.y
        return ceil(totalHeight)
    }
    
}

// MARK: - Layout

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
        updateInlineAttachmentViews()
    }
    #elseif canImport(UIKit)
    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
        updateInlineAttachmentViews()
    }
    #endif
}

// MARK: - Attachment Views

extension InlineAttachmentTextView {
    func updateInlineAttachmentViews() {
        guard let textLayoutManager else { return }
        
        textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)
        
        var visibleAttachmentViews = Set<ObjectIdentifier>()
        var didUseTextAttachmentViewProvider = false
        textLayoutManager.enumerateTextLayoutFragments(
            from: textLayoutManager.documentRange.location,
            options: [.ensuresLayout]
        ) { [weak self] textLayoutFragment in
            guard let self else { return false }
            
            let fragmentOrigin = textLayoutFragment.layoutFragmentFrame.origin
            for textAttachmentViewProvider in textLayoutFragment.textAttachmentViewProviders {
                didUseTextAttachmentViewProvider = true
                let attachmentFrame = textLayoutFragment.frameForTextAttachment(
                    at: textAttachmentViewProvider.location
                )
                guard !attachmentFrame.isEmpty,
                      let attachmentView = textAttachmentViewProvider.view else {
                    continue
                }
                
                var frame = attachmentFrame
                frame.origin.x += fragmentOrigin.x + textContainerOffset.x
                frame.origin.y += fragmentOrigin.y + textContainerOffset.y
                attachmentView.frame = frame
                
                if attachmentView.superview !== self {
                    addSubview(attachmentView)
                }
                
                let attachmentViewID = ObjectIdentifier(attachmentView)
                visibleAttachmentViews.insert(attachmentViewID)
                inlineAttachmentViews[attachmentViewID] = attachmentView
            }
            
            return true
        }
        
        if !didUseTextAttachmentViewProvider {
            updateInlineAttachmentViewsUsingTextSegments(
                visibleAttachmentViews: &visibleAttachmentViews
            )
        }
        
        for (attachmentViewID, attachmentView) in inlineAttachmentViews
            where !visibleAttachmentViews.contains(attachmentViewID) {
            attachmentView.removeFromSuperview()
            inlineAttachmentViews[attachmentViewID] = nil
        }
    }
    
    private func updateInlineAttachmentViewsUsingTextSegments(
        visibleAttachmentViews: inout Set<ObjectIdentifier>
    ) {
        guard let textLayoutManager,
              let textContentManager,
              let textStorage = _textContentStorage?.textStorage ?? _textStorage else {
            return
        }
        
        let storageRange = NSRange(location: 0, length: textStorage.length)
        textStorage.enumerateAttribute(.attachment, in: storageRange) { value, range, _ in
            guard let inlineHostingAttachment = value as? InlineHostingAttachment,
                  let textRange = NSTextRange(range, textContentManager: textContentManager) else {
                return
            }
            
            var firstFrame: CGRect?
            var baseline: CGFloat = .zero
            textLayoutManager.enumerateTextSegments(
                in: textRange,
                type: .standard,
                options: [.rangeNotRequired]
            ) { _, segmentFrame, segmentBaseline, _ in
                firstFrame = segmentFrame
                baseline = segmentBaseline
                return false
            }
            
            guard let segmentFrame = firstFrame,
                  !segmentFrame.isEmpty else {
                return
            }
            
            let attachmentView = MainActor.assumeIsolated {
                inlineHostingAttachment.hostingView
            }
            
            var frame = CGRect(origin: textContainerOffset, size: attachmentView.intrinsicContentSize)
            frame.origin.x += segmentFrame.origin.x
            frame.origin.y += baseline + segmentFrame.minY
            frame.origin.y -= inlineHostingAttachment.ascender ?? attachmentView.intrinsicContentSize.height
            attachmentView.frame = frame
            
            if attachmentView.superview !== self {
                addSubview(attachmentView)
            }
            
            let attachmentViewID = ObjectIdentifier(attachmentView)
            visibleAttachmentViews.insert(attachmentViewID)
            inlineAttachmentViews[attachmentViewID] = attachmentView
        }
    }
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

// MARK: - Helpers

extension InlineAttachmentTextView {
    /// An optional value of `NSLayoutManager` for cross-platform code statbility.
    ///
    /// - warning: Calling this would switch to TextKit 1 and cause layout or behavior changes.
    @available(*, deprecated, message: "Calling this would switch to TextKit 1.")
    var _layoutManager: NSLayoutManager? {
        self.layoutManager
    }
    
    /// An optional value of `NSTextContainer` for cross-platform code statbility.
    ///
    /// For UIKit, this is guaranteed to be non-`nil`. For AppKit, this could be `nil`.
    var _textContainer: NSTextContainer? {
        self.textContainer
    }
    
    /// An optional value of `NSTextStorage` for cross-platform code statbility.
    ///
    /// For UIKit, this is guaranteed to be non-`nil`. For AppKit, this could be `nil`.
    var _textStorage: NSTextStorage? {
        self.textStorage
    }
}

private extension TextAlignment {
    var _richTextStorageValue: Int {
        switch self {
            case .leading:
                return 0
            case .center:
                return 1
            case .trailing:
                return 2
            @unknown default:
                return -1
        }
    }
}

private extension LayoutDirection {
    var _richTextStorageValue: Int {
        switch self {
            case .leftToRight:
                return 0
            case .rightToLeft:
                return 1
            @unknown default:
                return -1
        }
    }
}

private extension Text.TruncationMode {
    var _richTextStorageValue: Int {
        switch self {
            case .head:
                return 0
            case .middle:
                return 1
            case .tail:
                return 2
            @unknown default:
                return -1
        }
    }
}

// MARK: - Auxiliary

fileprivate extension NSMutableAttributedString {
    func _fixForgroundColorIfNecessary(in range: NSRange) {
        enumerateAttributes(
            in: range,
            options: []
        ) { attrs, range, _ in
            if attrs[.foregroundColor] == nil {
                #if canImport(AppKit)
                addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
                #elseif canImport(UIKit)
                addAttribute(.foregroundColor, value: UIColor.label, range: range)
                #endif
            }
        }
    }
    
    func _fixFont(_ font: PlatformFont?, in range: NSRange) {
        let font: PlatformFont = font ?? {
            #if canImport(AppKit)
            return NSFont.systemFont(ofSize: NSFont.systemFontSize)
            #elseif canImport(UIKit)
            return UIFont.preferredFont(forTextStyle: .body)
            #endif
        }()
        
        enumerateAttributes(
            in: range,
            options: []
        ) { attrs, range, _ in
            if attrs[.font] == nil {
                addAttribute(.font, value: font, range: range)
            }
        }
    }
}
