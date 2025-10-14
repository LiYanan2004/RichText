//
//  _FormatParser.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/14.
//  Credits to Codex.
//

import Foundation

enum _FormatParser {
    struct Result {
        struct Segment {
            let literal: String
            let placeholder: String
        }

        let segments: [Segment]
        let trailingLiteral: String
    }
    
    static func parse(key: String, argumentCount: Int) -> Result? {
        var segments: [Result.Segment] = []
        var literal = ""
        var index = key.startIndex
        var placeholders = 0

        while index < key.endIndex {
            let character = key[index]

            if character == "%" {
                let nextIndex = key.index(after: index)

                if nextIndex < key.endIndex, key[nextIndex] == "%" {
                    literal.append("%")
                    index = key.index(after: nextIndex)
                    continue
                }

                guard let specifierEnd = consumeSpecifier(in: key, startingAt: index) else {
                    return nil
                }

                let placeholder = String(key[index..<specifierEnd])
                segments.append(.init(literal: literal, placeholder: placeholder))
                literal.removeAll(keepingCapacity: true)
                index = specifierEnd
                placeholders += 1
                continue
            }

            literal.append(character)
            index = key.index(after: index)
        }

        guard placeholders == argumentCount else {
            return nil
        }

        return Result(segments: segments, trailingLiteral: literal)
    }

    private static func consumeSpecifier(in format: String, startingAt start: String.Index) -> String.Index? {
        var index = format.index(after: start)
        guard index < format.endIndex else {
            return nil
        }

        func advanceWhile(_ predicate: (Character) -> Bool) {
            while index < format.endIndex && predicate(format[index]) {
                index = format.index(after: index)
            }
        }

        // Parameter (e.g. 2$)
        let digits = CharacterSet.decimalDigits
        var parameterIndex = index
        while parameterIndex < format.endIndex, format[parameterIndex].unicodeScalars.allSatisfy(digits.contains) {
            parameterIndex = format.index(after: parameterIndex)
        }
        if parameterIndex != index {
            index = parameterIndex
            if index < format.endIndex, format[index] == "$" {
                index = format.index(after: index)
            }
        }

        // Flags
        let flags = "-+ #0'"
        advanceWhile { flags.contains($0) }

        // Width
        if index < format.endIndex, format[index] == "*" {
            index = format.index(after: index)
            var widthIndex = index
            while widthIndex < format.endIndex, format[widthIndex].unicodeScalars.allSatisfy(digits.contains) {
                widthIndex = format.index(after: widthIndex)
            }
            if widthIndex < format.endIndex, format[widthIndex] == "$" {
                widthIndex = format.index(after: widthIndex)
            }
            index = widthIndex
        } else {
            advanceWhile { $0.unicodeScalars.allSatisfy(digits.contains) }
        }

        // Precision
        if index < format.endIndex, format[index] == "." {
            index = format.index(after: index)
            if index < format.endIndex, format[index] == "*" {
                index = format.index(after: index)
                var precisionIndex = index
                while precisionIndex < format.endIndex, format[precisionIndex].unicodeScalars.allSatisfy(digits.contains) {
                    precisionIndex = format.index(after: precisionIndex)
                }
                if precisionIndex < format.endIndex, format[precisionIndex] == "$" {
                    precisionIndex = format.index(after: precisionIndex)
                }
                index = precisionIndex
            } else {
                advanceWhile { $0.unicodeScalars.allSatisfy(digits.contains) }
            }
        }

        // Length modifiers
        let modifiers = ["hh", "ll", "h", "l", "L", "z", "t", "j", "q"]
        if index < format.endIndex {
            for modifier in modifiers {
                if format[index...].hasPrefix(modifier) {
                    index = format.index(index, offsetBy: modifier.count)
                    break
                }
            }
        }

        guard index < format.endIndex else {
            return nil
        }

        index = format.index(after: index)
        return index
    }
}
