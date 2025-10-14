//
//  ResolvedLocalizedStringKey.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/14.
//

import SwiftUI

package struct ResolvedLocalizedStringKey {
    private var _localizedStringKey: LocalizedStringKey
    
    package init(_ key: LocalizedStringKey) {
        self._localizedStringKey = key
    }
    
    @inlinable package var key: String? {
        _localizedStringKey._key
    }
    
    @inlinable package var args: [Any]? {
        _localizedStringKey._args
    }
    
    @inlinable package func localizedString(
        tableName: String? = nil,
        bundle: Bundle? = nil,
        comment: StaticString? = nil
    ) -> String? {
        _localizedStringKey._localizedString(
            tableName: tableName,
            bundle: bundle,
            comment: comment
        )
    }
}

fileprivate extension LocalizedStringKey {
    var _key: String? {
        let mirror = Mirror(reflecting: self)
        guard let key = mirror.descendant("key") as? String else {
            return nil
        }
        return key
    }
    
    var _args: [Any]? {
        let mirror = Mirror(reflecting: self)
        guard let args = mirror.descendant("arguments") as? [Any] else {
            return nil
        }
        return args
    }
    
    func _localizedString(
        tableName: String? = nil,
        bundle: Bundle? = nil,
        comment: StaticString? = nil
    ) -> String? {
        guard let key = _key else {
            return nil
        }

        guard let rawArguments = _args, !rawArguments.isEmpty else {
            return String(
                localized: LocalizedStringResource(
                    .init(key),
                    table: tableName,
                    bundle: bundle ?? .main,
                    comment: comment
                )
            )
        }

        if let interpolation = Self._resolveUsingInterpolation(
            key: key,
            rawArguments: rawArguments
        ) {
            // Localized with args
            return String(
                localized: LocalizedStringResource(
                    .init(stringInterpolation: interpolation),
                    table: tableName,
                    bundle: bundle ?? .main,
                    comment: comment
                )
            )
        } else {
            // Non-localized with args
            let legacyValues = rawArguments.map { Self._legacyValue(from: $0) }
            let cVarArgs = legacyValues.compactMap(Self._cVarArg)
            
            guard cVarArgs.count == legacyValues.count else {
                return nil
            }
            
            return String.localizedStringWithFormat(key, cVarArgs)
        }
    }

    private static func _resolveUsingInterpolation(
        key: String,
        rawArguments: [Any]
    ) -> LocalizedStringResource.StringInterpolation? {
        guard let parsed = _FormatParser.parse(key: key, argumentCount: rawArguments.count) else {
            return nil
        }

        var interpolation = LocalizedStringResource.StringInterpolation(
            literalCapacity: key.count,
            interpolationCount: rawArguments.count
        )

        for (index, segment) in parsed.segments.enumerated() {
            interpolation.appendLiteral(segment.literal)
            guard _appendArgument(rawArguments[index], placeholder: segment.placeholder, into: &interpolation) else {
                return nil
            }
        }

        interpolation.appendLiteral(parsed.trailingLiteral)

        return interpolation
    }

    private static func _appendArgument(
        _ rawArgument: Any,
        placeholder: String,
        into interpolation: inout LocalizedStringResource.StringInterpolation
    ) -> Bool {
        guard let info = _argumentInfo(from: rawArgument) else {
            return false
        }

        if let formatter = info.formatter, let value = _unwrapOptional(info.rawValue) {
            if let formatted = formatter.string(for: value) {
                interpolation.appendInterpolation(formatted)
                return true
            }
        }

        return _appendValue(
            info.rawValue,
            explicitSpecifier: info.specifier,
            placeholder: placeholder,
            into: &interpolation
        )
    }

    private static func _appendValue(
        _ rawValue: Any?,
        explicitSpecifier: String?,
        placeholder: String,
        into interpolation: inout LocalizedStringResource.StringInterpolation
    ) -> Bool {
        guard let value = _unwrapOptional(rawValue) else {
            interpolation.appendLiteral("")
            return true
        }

        let specifier = explicitSpecifier ?? placeholder

        switch value {
        case let intValue as Int:
            _appendInteger(Int64(intValue), specifier: specifier, into: &interpolation)
            return true
        case let intValue as Int64:
            _appendInteger(intValue, specifier: specifier, into: &interpolation)
            return true
        case let intValue as Int32:
            _appendInteger(Int64(intValue), specifier: specifier, into: &interpolation)
            return true
        case let intValue as Int16:
            _appendInteger(Int64(intValue), specifier: specifier, into: &interpolation)
            return true
        case let intValue as Int8:
            _appendInteger(Int64(intValue), specifier: specifier, into: &interpolation)
            return true
        case let uintValue as UInt:
            _appendUnsigned(UInt64(uintValue), specifier: specifier, into: &interpolation)
            return true
        case let uintValue as UInt64:
            _appendUnsigned(uintValue, specifier: specifier, into: &interpolation)
            return true
        case let uintValue as UInt32:
            _appendUnsigned(UInt64(uintValue), specifier: specifier, into: &interpolation)
            return true
        case let uintValue as UInt16:
            _appendUnsigned(UInt64(uintValue), specifier: specifier, into: &interpolation)
            return true
        case let uintValue as UInt8:
            _appendUnsigned(UInt64(uintValue), specifier: specifier, into: &interpolation)
            return true
        case let floatValue as Float:
            _appendFloating(Double(floatValue), specifier: specifier, into: &interpolation)
            return true
        case let cgValue as CGFloat:
            _appendFloating(Double(cgValue), specifier: specifier, into: &interpolation)
            return true
        case let doubleValue as Double:
            _appendFloating(doubleValue, specifier: specifier, into: &interpolation)
            return true
        case let boolValue as Bool:
            _appendInteger(boolValue ? 1 : 0, specifier: specifier, into: &interpolation)
            return true
        case let stringValue as String:
            interpolation.appendInterpolation(stringValue)
            return true
        case let attributed as AttributedString:
            interpolation.appendInterpolation(String(attributed.characters))
            return true
        case let text as Text:
            interpolation.appendInterpolation(text._rawOrResolvedString)
            return true
        case let key as LocalizedStringKey:
            if let resolved = key._localizedString() {
                interpolation.appendInterpolation(resolved)
                return true
            }
            return false
        case let number as NSNumber:
            interpolation.appendInterpolation(number)
            return true
        case let object as NSObject:
            interpolation.appendInterpolation(object)
            return true
        default:
            interpolation.appendInterpolation(String(describing: value))
            return true
        }
    }

    private static func _appendInteger(
        _ value: Int64,
        specifier: String?,
        into interpolation: inout LocalizedStringResource.StringInterpolation
    ) {
        if let specifier, !specifier.isEmpty {
            interpolation.appendInterpolation(value, specifier: specifier)
        } else {
            interpolation.appendInterpolation(value)
        }
    }

    private static func _appendUnsigned(
        _ value: UInt64,
        specifier: String?,
        into interpolation: inout LocalizedStringResource.StringInterpolation
    ) {
        if let specifier, !specifier.isEmpty {
            interpolation.appendInterpolation(value, specifier: specifier)
        } else {
            interpolation.appendInterpolation(value)
        }
    }

    private static func _appendFloating(
        _ value: Double,
        specifier: String?,
        into interpolation: inout LocalizedStringResource.StringInterpolation
    ) {
        if let specifier, !specifier.isEmpty {
            interpolation.appendInterpolation(value, specifier: specifier)
        } else {
            interpolation.appendInterpolation(value)
        }
    }

    private static func _argumentInfo(from rawArgument: Any) -> _InterpolationValue? {
        let mirror = Mirror(reflecting: rawArgument)

        if let tuple = mirror.descendant("storage", "value") {
            let tupleMirror = Mirror(reflecting: tuple)
            let rawValue = tupleMirror.children.first(where: { $0.label == ".0" })?.value
            let specifierOrFormatter = tupleMirror.children.first(where: { $0.label == ".1" })?.value

            return _InterpolationValue(
                rawValue: rawValue,
                specifier: specifierOrFormatter as? String,
                formatter: specifierOrFormatter as? Formatter
            )
        }

        if let text = mirror.descendant("storage", "text", ".0") as? Text {
            return _InterpolationValue(rawValue: text._rawOrResolvedString, specifier: nil, formatter: nil)
        }

        if let format = mirror.descendant("storage", "formatStyleValue", "format") as? any FormatStyle,
           let input = mirror.descendant("storage", "formatStyleValue", "input") {
            return _InterpolationValue(rawValue: format.format(any: input), specifier: nil, formatter: nil)
        }

        return nil
    }

    private static func _legacyValue(from rawArgument: Any) -> Any? {
        guard let info = _argumentInfo(from: rawArgument) else {
            return nil
        }

        if let formatter = info.formatter, let value = _unwrapOptional(info.rawValue) {
            return formatter.string(for: value)
        }

        return _unwrapOptional(info.rawValue)
    }

    private static func _cVarArg(from value: Any?) -> CVarArg? {
        switch value {
        case let int as Int:      return int
        case let int as Int64:    return int
        case let int as Int32:    return int
        case let int as Int16:    return int
        case let int as Int8:     return int
        case let uint as UInt:    return uint
        case let uint as UInt64:  return uint
        case let uint as UInt32:  return uint
        case let uint as UInt16:  return uint
        case let uint as UInt8:   return uint
        case let float as Float:  return float
        case let cg as CGFloat:   return cg
        case let double as Double:return double
        case let string as NSString: return string
        case let string as String:   return string as NSString
        case let number as NSNumber: return number
        case let object as NSObject: return object
        default:                     return nil
        }
    }

    private static func _unwrapOptional(_ value: Any?) -> Any? {
        guard let wrapped = value else {
            return nil
        }

        let mirror = Mirror(reflecting: wrapped)
        if mirror.displayStyle != .optional {
            return wrapped
        }

        guard let child = mirror.children.first else {
            return nil
        }

        return _unwrapOptional(child.value)
    }
}
