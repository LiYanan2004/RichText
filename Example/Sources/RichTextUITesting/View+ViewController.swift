//
//  View+ViewController.swift
//  RichText
//
//  Created by Yanan Li on 2026/3/19.
//

import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
extension SwiftUI.View {
    func _viewController() -> some NSViewController {
        SwiftUI.NSHostingController(rootView: self)
    }
}
#else
extension SwiftUI.View {
    func _viewController() -> some UIViewController {
        SwiftUI.UIHostingController(rootView: self)
    }
}
#endif
