//
//  Created by Marcin Krzyzanowski on 07/08/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//
//  Adjusted to the needs of specific projects by Robert Geifman in 2018
//

import FoundationAdditions
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public protocol AnyScene {
#if os(macOS)
	typealias Identifier = NSUserInterfaceItemIdentifier // NSStoryboard.SceneIdentifier
#elseif os(iOS) || os(tvOS)
	typealias Identifier = String
#endif
	var identifier: Identifier? { get }
}

public func == (_ a: AnyScene, _ b: AnyScene) -> Bool {
	a.identifier == b.identifier
}

// MARK: - Misc
public extension Optional where Wrapped == String {
	var unwrappedString: String {
		switch self {
		case .none: return "nil"
		case .some(let value): return "\(value)"
		}
	}
}

public extension Sequence {
	func first<Result>(_ isMatch: (Iterator.Element) -> Result?) -> Result? {
		for element in self {
			if let result = isMatch(element) {
				return result
			}
		}
		return nil
	}
}

public extension Collection {
	var second: Iterator.Element? {
		index(startIndex, offsetBy: 1, limitedBy: endIndex).map { self[$0] }
	}
}
