//
//  NSTextAlignment++.swift
//  RichText
//
//  Created by Yanan Li on 2026/6/20.
//

import SwiftUI

extension NSTextAlignment {
    init(_ textAlignment: TextAlignment, layoutDirection: LayoutDirection) {
        switch textAlignment {
            case .leading:
                self = layoutDirection == .leftToRight ? .left : .right
            case .trailing:
                self = layoutDirection == .leftToRight ? .right : .left
            case .center:
                self = .center
            @unknown default:
                self = .center
        }
    }
}
