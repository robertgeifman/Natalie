//
//  Interoperability.swift
//  LoopyCore
//
//  Created by Robert Geifman on 21/05/2019.
//  Copyright © 2019 Robert Geifman. All rights reserved.
//

#if os(macOS)
import AppKit
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

////////////////////////////////////////////////////////////
public extension CGColorSpace {
	var stringValue: String { name == nil ? "unknown" : String(name!) }
}
public extension CGColorSpaceModel {
	var stringValue: String {
		switch self {
		case .unknown: return "unknown"
		case .monochrome: return "monochrome"
		case .rgb: return "rgb"
		case .cmyk: return "cmyk"
		case .lab: return "lab"
		case .deviceN: return "deviceN"
		case .indexed: return "indexed"
		case .pattern: return "pattern"
		case .XYZ: return "XYZ"
		@unknown default: return "unknown"
		}
	}
}

#if os(macOS)
/*
public typealias ViewController = NSViewController
public typealias View = NSView
public typealias StackView = NSStackView
public typealias CollectionView = NSCollectionView
public typealias CollectionViewDataSource = NSCollectionViewDataSource
public typealias CollectionViewDelegate = NSCollectionViewDelegate
*/
/*
public typealias CollectionViewLayout = NSCollectionViewLayout
public typealias CollectionViewTransitionLayout = NSCollectionViewTransitionLayout
public typealias CollectionViewFlowLayout = NSCollectionViewFlowLayout
public typealias CollectionViewGridLayout = NSCollectionViewGridLayout
*/
public typealias LayoutOrientation = NSLayoutConstraint.Orientation
public typealias Responder = NSResponder
// public typealias Window = NSWindow
public typealias Application = NSApplication
public typealias ApplicationDelegate = NSApplicationDelegate
public typealias Color = NSColor
public typealias ColorSpace = NSColorSpace
// public typealias LayoutGuide = NSLayoutGuide
public typealias LayoutPriority = NSLayoutConstraint.Priority
public extension LayoutPriority {
	var description: String {
		switch self {
		case .required: return ".required"
		case .defaultHigh: return ".defaultHigh"
		case .defaultLow: return ".defaultLow"
#if os(macOS)
		case .dragThatCanResizeWindow: return ".dragThatCanResizeWindow"
		case .windowSizeStayPut: return ".windowSizeStayPut"
		case .dragThatCannotResizeWindow: return ".dragThatCannotResizeWindow"
		case .fittingSizeCompression: return ".fittingSizeCompression"
#endif
		default: return "\(rawValue)"
		}
	}
}

public extension ColorSpace {
	var model: ColorSpaceModel { colorSpaceModel }
	var stringValue: String { localizedName ?? "unknown" }
}
public typealias ColorSpaceModel = NSColorSpace.Model
public extension ColorSpaceModel {
	var stringValue: String {
		switch self {
		case .unknown: return "unknown"
		case .gray: return "gray"
		case .rgb: return "rgb"
		case .cmyk: return "cmyk"
		case .lab: return "lab"
		case .deviceN: return "deviceN"
		case .indexed: return "indexed"
		case .patterned: return "patterned"
		@unknown default: return "unknown"
		}
	}
}
public typealias Font = NSFont
public typealias BezierPath = NSBezierPath

public typealias CGEdgeInsets = NSEdgeInsets
public extension CGEdgeInsets {
	static let zero = CGEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
	static func == (insets1: Self, insets2: Self) -> Bool {
		return insets1.top == insets2.top && insets1.bottom == insets2.bottom &&
			insets1.left == insets2.left && insets1.right == insets2.right
	}
}

// MARK: - DirectionalEdgeInsets
// specify amount to inset (positive) for each of the edges. values can be negative to 'outset'
public struct CGDirectionalEdgeInsets {
	public static let zero = CGDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
	
	public var top: CGFloat
	public var leading: CGFloat
	public var bottom: CGFloat
	public var trailing: CGFloat
	
	public init(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) {
		self.top = top
		self.leading = leading
		self.bottom = bottom
		self.trailing = trailing
	}
	
	public static func == (insets1: Self, insets2: Self) -> Bool {
		return insets1.top == insets2.top && insets1.bottom == insets2.bottom &&
			insets1.leading == insets2.leading && insets1.trailing == insets2.trailing
	}
}

// MARK: - Offset
public struct CGOffset {
	// specify amount to offset a position, positive for right or down, negative for left or up
	public static let zero = CGOffset(horizontal: 0, vertical: 0)
	public var horizontal: CGFloat
	public var vertical: CGFloat
	public init(horizontal: CGFloat, vertical: CGFloat) {
		self.horizontal = horizontal
		self.vertical = vertical
	}
	static func == (offset1: CGOffset, offset2: CGOffset) -> Bool {
		return offset1.horizontal == offset2.horizontal && offset1.vertical == offset2.vertical
	}
}

extension NSUserInterfaceItemIdentifier: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		self.init(rawValue: value)
	}
}
////////////////////////////////////////////////////////////
#elseif os(iOS) || os(tvOS)
import UIKit
/*
public typealias ViewController = UIViewController
public typealias View = UIView
public typealias StackView = UIStackView
public typealias CollectionView = UICollectionView
public typealias CollectionViewDataSource = UICollectionViewDataSource
public typealias CollectionViewDelegate = UICollectionViewDelegate
public typealias CollectionViewLayout = UICollectionViewLayout
public typealias CollectionViewTransitionLayout = UICollectionViewTransitionLayout
public typealias CollectionViewFlowLayout = UICollectionViewFlowLayout
public typealias Window = UIWindow
*/
public typealias LayoutGuide = UILayoutGuide
public typealias LayoutPriority = UILayoutPriority
public typealias LayoutOrientation = NSLayoutConstraint.Axis
public typealias Responder = UIResponder
public typealias Application = UIApplication
public typealias ApplicationDelegate = UIApplicationDelegate
public typealias Color = UIColor
public typealias ColorSpace = CGColorSpace
public typealias ColorSpaceModel = CGColorSpaceModel
public typealias Font = UIFont
public typealias BezierPath = UIBezierPath
public typealias CGDirectionalEdgeInsets = NSDirectionalEdgeInsets
public extension NSDirectionalEdgeInsets {
	static let zero = Self(top: 0, leading: 0, bottom: 0, trailing: 0)
}
public typealias CGEdgeInsets = UIEdgeInsets
public extension CGEdgeInsets {
	static let zero = Self(top: 0, left: 0, bottom: 0, right: 0)
}
public typealias CGOffset = UIOffset
#endif

public typealias NSLayoutAttribute = NSLayoutConstraint.Attribute
public typealias LayoutRelation = NSLayoutConstraint.Relation

////////////////////////////////////////////////////////////
extension LayoutPriority: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
	public init(integerLiteral value: Int) {
		self.init(rawValue: Float(value))
	}

	public init(floatLiteral value: Double) {
		self.init(rawValue: Float(value))
	}
}

////////////////////////////////////////////////////////////
// MARK: - Transparent Colors
// swiftlint:disable object_literal
public extension CGColor {
#if os(macOS)
	static let transparentRGB = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
	static let transparentCMYK = CGColor(genericCMYKCyan: 0, magenta: 0, yellow: 0, black: 0, alpha: 0)
#elseif os(iOS) || os(tvOS)
	static let transparentRGB = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0)
#endif
}
#if os(macOS)
public extension NSColor {
	static let transparentRGB = NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 0)
	static let transparentCMYK = NSColor(deviceCyan: 0, magenta: 0, yellow: 0, black: 0, alpha: 0)
}
#elseif os(iOS) || os(tvOS)
public extension UIColor {
	static let transparentRGB = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
}
#endif
// swiftlint:enable object_literal
