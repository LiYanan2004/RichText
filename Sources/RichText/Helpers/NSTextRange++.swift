//
//  NSTextRange++.swift
//  RichText
//
//  Created by Yanan Li on 2026/6/20.
//

import SwiftUI

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
