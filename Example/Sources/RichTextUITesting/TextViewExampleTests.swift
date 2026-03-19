//
//  TextViewExampleTests.swift
//  RichText
//
//  Created by Yanan Li on 2026/3/19.
//

import Testing
import SwiftUI
import SnapshotTesting
@testable import RichTextExample

@MainActor
@Suite("Example UI Tests", .snapshots)
struct TextViewExampleTests {
    #if canImport(AppKit)
    let frameworkName = "AppKit"
    #elseif canImport(UIKit)
    let frameworkName = "UIKit"
    #endif
    
    @Test("Hello RichText")
    func testHelloRichText() async throws {
        let snapshotSize = CGSize(width: 300, height: 300)
        assertSnapshot(
            of: HelloRichTextExample()._viewController(),
            as: .image(size: snapshotSize),
            named: frameworkName
        )
    }
    
    @Test("Inline Presentation")
    func testInlinePresentation() async throws {
        let snapshotSize = CGSize(width: 300, height: 300)
        assertSnapshot(
            of: InlinePresentationExample()._viewController(),
            as: .image(size: snapshotSize),
            named: frameworkName
        )
    }
    
    @Test("Inline SwiftUI View")
    func testInlineSwiftUIView() async throws {
        let snapshotSize = CGSize(width: 300, height: 300)
        
        assertSnapshot(
            of: EmbedSwiftUIViewExample()._viewController(),
            as: .image(size: snapshotSize),
            named: frameworkName
        )
    }
}
