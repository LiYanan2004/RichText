//
//  Text.LineStyle++.swift
//  RichText
//
//  Created by Yanan Li on 2026/6/20.
//

import SwiftUI

extension Text.LineStyle {
    var color: Color? {
        return Mirror(reflecting: self).descendant("color") as? Color
    }
}
