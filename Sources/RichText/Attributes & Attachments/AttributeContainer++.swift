//
//  AttributeContainer++.swift
//  RichText
//
//  Created by Yanan Li on 2026/3/12.
//

import Foundation
import SwiftUI

extension AttributeContainer {
    mutating func mergeParagraphStyle(
        mergePolicy: AttributedString.AttributeMergePolicy = .keepNew,
        perform transform: (NSMutableParagraphStyle) -> Void
    ) {
        #if canImport(AppKit)
        let paragraphStyle = self[keyPath: \.appKit.paragraphStyle] ?? .init()
        #elseif canImport(UIKit)
        let paragraphStyle = self[keyPath: \.uiKit.paragraphStyle] ?? .init()
        #else
        fatalError()
        #endif
        
        let result = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle
        if let result {
            transform(result)
            merge(AttributeContainer([.paragraphStyle : result]), mergePolicy: mergePolicy)
        }
    }
}
