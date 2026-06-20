//
//  InlineAttachmentTextView+Storage.swift
//  RichText
//
//  Created by Yanan Li on 2026/6/20.
//

import SwiftUI

extension InlineAttachmentTextView {
    
    func updateStorageContents(
        with attributedString: NSAttributedString,
        usingEditingTransaction usesEditingTransaction: Bool = true
    ) {
        if usesEditingTransaction {
            updateStorageContentsWithTransaction(attributedString: attributedString)
        } else {
            updateStorageContentsWithoutTransaction(attributedString: attributedString)
        }
    }
    
    private func updateStorageContentsWithTransaction(attributedString: NSAttributedString) {
        if let textContentManager {
            // TK2 path: mutate content inside the content manager transaction.
            textContentManager.performEditingTransaction {
                updateStorageContentsWithoutTransaction(attributedString: attributedString)
            }
        } else {
            // TK1 path: mutate NSTextStorage inside an editing batch.
            _textStorage?.beginEditing()
            updateStorageContentsWithoutTransaction(attributedString: attributedString)
            _textStorage?.endEditing()
        }
    }
    
    private func updateStorageContentsWithoutTransaction(attributedString: NSAttributedString) {
        if let textContentStorage = _textContentStorage {
            // TK2 path: update the concrete content storage directly.
            textContentStorage.attributedString = attributedString
        } else if let textLayoutManager {
            // TK2 path: update through NSTextLayoutManager when no content storage exists.
            textLayoutManager.replaceContents(
                in: textLayoutManager.documentRange,
                with: attributedString
            )
        } else if let textStorage = _textStorage {
            // TK1 path: update the legacy NSTextStorage contents.
            if appendNewSuffixIfPossible(
                from: attributedString,
                to: textStorage
            ) {
                return
            }
            textStorage.setAttributedString(attributedString)
        }
    }
    
    private func appendNewSuffixIfPossible(
        from attributedString: NSAttributedString,
        to textStorage: NSTextStorage
    ) -> Bool {
        guard attributedString.length > textStorage.length else {
            return false
        }
        
        let existingRange = NSRange(location: 0, length: textStorage.length)
        let existingPrefix = attributedString.attributedSubstring(from: existingRange)
        guard textStorage.isEqual(to: existingPrefix) else {
            return false
        }
        
        let appendedRange = NSRange(
            location: textStorage.length,
            length: attributedString.length - textStorage.length
        )
        textStorage.append(attributedString.attributedSubstring(from: appendedRange))
        return true
    }
}
