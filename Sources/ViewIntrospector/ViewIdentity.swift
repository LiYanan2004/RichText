//
//  ViewIdentity.swift
//  ViewIntrospector
//
//  Created by Yanan Li on 2025/10/7.
//

import SwiftUI

/// SwiftUI view identity introspector.
///
/// This introspector try to find the `IDView` within the view hierarchy and extract `id` from it.
///
/// ### How it works
///
/// When applying `.id(_:)` to a view, SwiftUI will wrap the view with `IDView`.
/// Your specified `id` will store in `IDView` as a property
///
/// Here are some references of how `id`view modifier works:
///
/// ```swift
/// @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
/// @_originallyDefinedIn(module: "SwiftUI", iOS 18.0)
/// @_originallyDefinedIn(module: "SwiftUI", macOS 15.0)
/// @_originallyDefinedIn(module: "SwiftUI", tvOS 18.0)
/// @_originallyDefinedIn(module: "SwiftUI", watchOS 11.0)
/// extension SwiftUICore.View {
///    @inlinable nonisolated public func id<ID>(_ id: ID) -> some SwiftUICore.View where ID : Swift.Hashable {
///       return IDView(self, id: id)
///    }
/// }
/// ```
package enum ViewIdentity {
    static package func explicit<Content: View>(_ root: Content) -> AnyHashable? {
        if let directID = descend(mirror: Mirror(reflecting: root)) {
            return directID
        }
        
        // TODO: Accessing State's value outside of being installed on a View. This will result in a constant Binding of the initial value and will not update.
//            if Content.Body.self != Never.self,
//               let wrappedID = explicit(root.body) {
//                return wrappedID
//            }
        
        return nil
    }
    
    private static func descend(
        mirror: Mirror
    ) -> AnyHashable? {
        let type = mirror.subjectType
        guard type != Never.self else { return nil }
        
        // Get the module name and the view type hierarchy.
        let typeName = String(reflecting: type)
        
        if typeName.starts(with: "SwiftUI.TupleView") {
            return nil
        }
        
        if typeName.starts(with: "SwiftUI.IDView"),
           let id = mirror.descendant("id") as? AnyHashable {
            return id
        }

        for child in mirror.children {
            guard let view = child.value as? (any SwiftUI.View) else { continue }
            if let found = explicit(view) {
                return found
            }
        }
        
        return nil
    }
}
