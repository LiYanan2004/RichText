//
//  FormatStyle++.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/14.
//

import Foundation

extension FormatStyle {
    func format(any value: Any) -> FormatOutput? {
        if let v = value as? FormatInput {
            return format(v)
        }
        return nil
    }
}

