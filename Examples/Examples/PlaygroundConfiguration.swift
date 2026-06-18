//
//  PlaygroundConfiguration.swift
//  Examples
//

import RichText
import SwiftUI

struct PlaygroundConfiguration {
    static let defaultValue = PlaygroundConfiguration()

    var fontSize = 17.0
    var kerning = 0.0
    var tracking = 0.0
    var baselineOffset = 0.0
    var lineSpacing = 4.0
    var textAlignment = PlaygroundTextAlignment.leading
    var lineLimit = 0
    var truncationMode = PlaygroundTruncationMode.tail
    var allowsTightening = false
    var attachmentWidth = 120.0
    var attachmentHeight = 60.0
    var attachmentSizing = PlaygroundAttachmentSizing.intrinsic
}

enum PlaygroundTextAlignment: String, CaseIterable, Identifiable {
    case leading
    case center
    case trailing

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }

    var textAlignment: TextAlignment {
        switch self {
        case .leading:
            .leading
        case .center:
            .center
        case .trailing:
            .trailing
        }
    }
}

enum PlaygroundTruncationMode: String, CaseIterable, Identifiable {
    case head
    case middle
    case tail

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }

    var truncationMode: Text.TruncationMode {
        switch self {
        case .head:
            .head
        case .middle:
            .middle
        case .tail:
            .tail
        }
    }
}

enum PlaygroundAttachmentSizing: String, CaseIterable, Identifiable {
    case intrinsic
    case fittingLineFragment

    var id: Self { self }

    var title: String {
        switch self {
        case .intrinsic:
            "Intrinsic"
        case .fittingLineFragment:
            "Fit Line"
        }
    }

    var hostedAttachmentSizing: HostedAttachmentSizing {
        switch self {
        case .intrinsic:
            .intrinsic
        case .fittingLineFragment:
            .fittingLineFragment
        }
    }
}
