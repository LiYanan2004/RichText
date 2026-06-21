//
//  InlineAttachmentTextView+Attachments.swift
//  RichText
//
//  Created by Yanan Li on 2026/6/20.
//

import SwiftUI

extension InlineAttachmentTextView {
    func updateInlineAttachmentViews() {
        var visibleAttachmentViews = Set<ObjectIdentifier>()
        
        if let textLayoutManager {
            // TK2 path: place attachment views from text layout fragments.
            updateInlineAttachmentViewsUsingTextKit2(
                textLayoutManager: textLayoutManager,
                visibleAttachmentViews: &visibleAttachmentViews
            )
        } else if let layoutManager = _layoutManager,
                  let textContainer = _textContainer {
            // TK1 path: place attachment views from glyph geometry.
            updateInlineAttachmentViewsUsingTextKit1(
                layoutManager: layoutManager,
                textContainer: textContainer,
                visibleAttachmentViews: &visibleAttachmentViews
            )
        }
        
        for (attachmentViewID, attachmentView) in inlineAttachmentViews {
            guard !visibleAttachmentViews.contains(attachmentViewID) else { continue }
            
            attachmentView.removeFromSuperview()
            inlineAttachmentViews[attachmentViewID] = nil
        }
    }
    
    var storageAttributedString: NSAttributedString? {
        if let textContentStorage = _textContentStorage {
            // TK2 path: NSTextContentStorage owns the attributed contents.
            return textContentStorage.attributedString
        }
        
        // TK1 path: NSTextStorage owns the attributed contents.
        return _textStorage
    }
    
    func refreshInlineAttachmentIndex() {
        inlineAttachmentsByID.removeAll(keepingCapacity: true)
        inlineAttachmentRangesByID.removeAll(keepingCapacity: true)
        
        guard let storageAttributedString else { return }
        
        let fullRange = NSRange(location: 0, length: storageAttributedString.length)
        storageAttributedString.enumerateAttribute(
            .attachment,
            in: fullRange,
            options: []
        ) { [weak self] value, range, _ in
            guard let self,
                  let attachment = value as? InlineHostingAttachment else {
                return
            }
            
            inlineAttachmentsByID[attachment.id] = attachment
            inlineAttachmentRangesByID[attachment.id] = range
        }
    }
}

// MARK: - TextKit 2

extension InlineAttachmentTextView {
    private func updateInlineAttachmentViewsUsingTextKit2(
        textLayoutManager: NSTextLayoutManager,
        visibleAttachmentViews: inout Set<ObjectIdentifier>
    ) {
        textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)

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
                
                let attachmentContainerView: PlatformView = {
                    if let richTextProvider = textAttachmentViewProvider as? InlineHostingAttachmentViewProvider,
                       let parentView = richTextProvider.richTextParentView {
                        return parentView
                    }
                    return self
                }()
                
                var frame = attachmentFrame
                frame.origin.x += fragmentOrigin.x
                frame.origin.y += fragmentOrigin.y
                if attachmentContainerView === self {
                    frame.origin.x += textContainerOffset.x
                    frame.origin.y += textContainerOffset.y
                }
                attachmentView.frame = frame
                
                if attachmentView.superview !== attachmentContainerView {
                    attachmentContainerView.addSubview(attachmentView)
                }
                
                let attachmentViewID = ObjectIdentifier(attachmentView)
                visibleAttachmentViews.insert(attachmentViewID)
                inlineAttachmentViews[attachmentViewID] = attachmentView
            }
            
            return true
        }
        
        if !didUseTextAttachmentViewProvider {
            // TK2 path: fall back to text segment geometry when no providers are present.
            updateInlineAttachmentViewsUsingTextSegments(
                visibleAttachmentViews: &visibleAttachmentViews
            )
        }
    }
    
    private func updateInlineAttachmentViewsUsingTextSegments(
        visibleAttachmentViews: inout Set<ObjectIdentifier>
    ) {
        guard let textLayoutManager,
              let textContentManager else {
            return
        }
        
        for (attachmentID, range) in inlineAttachmentRangesByID {
            guard let inlineHostingAttachment = inlineAttachmentsByID[attachmentID],
                  let textRange = NSTextRange(
                    range,
                    textContentManager: textContentManager
                  ) else {
                continue
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
            
            guard let segmentFrame = firstFrame, !segmentFrame.isEmpty else {
                continue
            }
            
            let attachmentView = MainActor.assumeIsolated {
                inlineHostingAttachment.attachmentsHostingTextView = self
                return inlineHostingAttachment.hostingView
            }
            
            var frame = CGRect(origin: textContainerOffset, size: segmentFrame.size)
            frame.origin.x += segmentFrame.origin.x
            frame.origin.y += baseline + segmentFrame.minY
            frame.origin.y -= inlineHostingAttachment.ascender ?? segmentFrame.height
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

// MARK: - TextKit 1

extension InlineAttachmentTextView {
    private func updateInlineAttachmentViewsUsingTextKit1(
        layoutManager: NSLayoutManager,
        textContainer: NSTextContainer,
        visibleAttachmentViews: inout Set<ObjectIdentifier>
    ) {
        guard let textStorage = layoutManager.textStorage else { return }

        layoutManager.ensureLayout(for: textContainer)
        let fullRange = NSRange(location: 0, length: textStorage.length)
        textStorage.enumerateAttribute(
            .attachment,
            in: fullRange,
            options: []
        ) { [weak self] value, characterRange, _ in
            guard let self,
                  let inlineHostingAttachment = value as? InlineHostingAttachment else {
                return
            }

            let glyphRange = layoutManager.glyphRange(
                forCharacterRange: characterRange,
                actualCharacterRange: nil
            )
            guard glyphRange.location != NSNotFound,
                  glyphRange.length > 0 else {
                return
            }

            var attachmentFrame = layoutManager.boundingRect(
                forGlyphRange: glyphRange,
                in: textContainer
            )
            guard !attachmentFrame.isEmpty else { return }

            attachmentFrame.origin.x += textContainerOffset.x
            attachmentFrame.origin.y += textContainerOffset.y

            let attachmentView = MainActor.assumeIsolated {
                inlineHostingAttachment.attachmentsHostingTextView = self
                return inlineHostingAttachment.hostingView
            }
            attachmentView.frame = attachmentFrame

            if attachmentView.superview !== self {
                addSubview(attachmentView)
            }

            let attachmentViewID = ObjectIdentifier(attachmentView)
            visibleAttachmentViews.insert(attachmentViewID)
            inlineAttachmentViews[attachmentViewID] = attachmentView
        }
    }
}
