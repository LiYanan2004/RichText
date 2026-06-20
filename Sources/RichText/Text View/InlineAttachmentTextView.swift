//
//  InlineAttachmentTextView.swift
//  RichText
//
//  Created by Yanan Li on 2025/8/24.
//

import SwiftUI

final class InlineAttachmentTextView: PlatformTextView {
    var inlineAttachmentViews: [ObjectIdentifier: PlatformView] = [:]
    var inlineAttachmentsByID: [AnyHashable: InlineHostingAttachment] = [:]
    var inlineAttachmentRangesByID: [AnyHashable: NSRange] = [:]
    var cachedContentHeight: CGFloat?
    var cachedContentHeightWidth: CGFloat?
    
    func replaceAttachmentWithEquivalentText(
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
    
    func applyAttributedStringPreservingAttachments(_ attributedString: AttributedString) {
        var mergedAttributedString = attributedString
        var changedAttachments: [InlineHostingAttachment] = []
        
        for newRun in mergedAttributedString.runs {
            guard let attachment = newRun[keyPath: \.inlineHostingAttachment],
                  let oldAttachment = inlineAttachmentsByID[attachment.id]
            else { continue }
            
            let didChangeIntrinsicContentSize = MainActor.assumeIsolated {
                oldAttachment.updateContent(from: attachment)
            }
            if didChangeIntrinsicContentSize {
                changedAttachments.append(oldAttachment)
            }
            
            mergedAttributedString[newRun.range].setAttributes(
                newRun.attributes.merging(
                    try! AttributeContainer(
                        [.inlineHostingAttachment : oldAttachment],
                        including: \.richText
                    ),
                    mergePolicy: .keepNew
                )
            )
        }
        
        setAttributedString(
            mergedAttributedString,
            invalidating: changedAttachments
        )
    }
    
    private func setAttributedString(
        _ attributedString: AttributedString,
        invalidating changedAttachments: [InlineHostingAttachment] = []
    ) {
        do {
            let attributed = try NSMutableAttributedString(
                attributedString: attributedString.nsAttributedString
            )
            let range = NSRange(location: 0, length: attributed.length)
            
            attributed._fixForgroundColorIfNecessary(in: range)
            attributed._fixFont(self.font, in: range)
            
            if storageAttributedStringMatches(attributed) {
                refreshInlineAttachmentIndex()
                changedAttachments.forEach { attachment in
                    invalidateTextLayout(for: attachment)
                }
                return
            }
            
            updateStorageContents(with: attributed)
            refreshInlineAttachmentIndex()
            
            _invalidateTextLayout()
        } catch {
            // TODO: use logger.
            print("Failed to build attributed string: \(error)")
        }
    }
    
    private func storageAttributedStringMatches(_ attributedString: NSAttributedString) -> Bool {
        guard let storageAttributedString else {
            return false
        }
        
        return storageAttributedString.isEqual(to: attributedString)
    }
}

extension InlineAttachmentTextView {
    /// The content manager used when the text view operates with TextKit 2.
    var textContentManager: NSTextContentManager? {
        textLayoutManager?.textContentManager
    }

    /// The content storage used when the text view operates with TextKit 2.
    var _textContentStorage: NSTextContentStorage? {
        textContentManager as? NSTextContentStorage
    }

    /// The legacy layout manager used when the text view operates with TextKit 1.
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
