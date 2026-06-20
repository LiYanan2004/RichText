//
//  NSLineBreakMode++.swift
//  RichText
//
//  Created by Yanan Li on 2026/6/20.
//

import SwiftUI

extension NSLineBreakMode {
    init(_ truncationMode: Text.TruncationMode, lineLimit: Int?) {
        let lineLimit = lineLimit ?? 0
        guard lineLimit > 0 else {
            self = .byWordWrapping
            return
        }
        
        switch truncationMode {
            case .head:
                self = .byTruncatingHead
            case .tail:
                self = .byTruncatingTail
            case .middle:
                self = .byTruncatingMiddle
            @unknown default:
                self = .byTruncatingTail
        }
    }
}
