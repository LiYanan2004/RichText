//
//  NSWritingDirection++.swift
//  RichText
//
//  Created by Yanan Li on 2026/6/20.
//

import SwiftUI

extension NSWritingDirection {
    init(_ layoutDirection: LayoutDirection) {
        switch layoutDirection {
            case .leftToRight:
                self = .leftToRight
            case .rightToLeft:
                self = .rightToLeft
            @unknown default:
                self = .natural
        }
    }
}
