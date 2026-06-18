//
//  HostedAttachmentSizing.swift
//  RichText
//
//  Created by Codex on 2026/6/17.
//

import Foundation

/// A sizing policy for SwiftUI views hosted inside text attachments.
public enum HostedAttachmentSizing: Sendable {
    /// Measures the hosted view using its platform intrinsic content size.
    case intrinsic
    /// Measures the hosted view using the available TextKit line fragment width.
    case fittingLineFragment
}
