//
//  Localized.swift
//  HairNet
//
//  Created by Robert Geifman on 2/12/19.
//  Copyright © 2019 Robert Geifman. All rights reserved.
//

#if os(OSX)
import AppKit
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

/// Returns a localized string, using the main bundle if one is not specified.
@inline(__always)
public func Localized(_ key: String, tableName: String? = nil, bundle: Bundle = Bundle.main, value: String = "", comment: String = "") -> String {
	NSLocalizedString(key, tableName:  tableName, bundle: bundle, value: value, comment: comment)
}

@inline(__always)
public func LocStr(_ key: String, tableName: String? = nil, bundle: Bundle = Bundle.main, value: String = "", comment: String = "") -> String {
	NSLocalizedString(key, tableName:  tableName, bundle: bundle, value: value, comment: comment)
}

public extension String {
	@inline(__always)
	init(_ key: String, tableName: String? = nil, bundle: Bundle = Bundle.main, value: String = "", comment: String = "") {
		self = NSLocalizedString(key, tableName:  tableName, bundle: bundle, value: value, comment: comment)
	}
}

