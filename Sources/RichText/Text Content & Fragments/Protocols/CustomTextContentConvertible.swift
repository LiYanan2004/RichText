//
//  CustomTextContentConvertible.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/7.
//


public protocol CustomTextContentConvertible {
    var textContent: TextViewContent { get }
}

public protocol InterFragment : CustomTextContentConvertible { }
