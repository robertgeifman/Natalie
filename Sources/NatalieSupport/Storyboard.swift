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

// MARK: - Storyboards
public protocol AnyStoryboard {
	typealias SegueIdentifier = String
	typealias Name = String
#if os(macOS)
	typealias Identifier = NSStoryboard.SceneIdentifier
	static var storyboard: NSStoryboard { get }
	static var identifier: NSStoryboard.Name { get }
#elseif os(iOS) || os(tvOS)
	typealias Identifier = String
	static var storyboard: UIStoryboard { get }
	static var identifier: UIStoryboard.Name { get }
#endif
}

#if os(macOS)
public extension AnyStoryboard {
	static var storyboard: NSStoryboard {
		.init(name: identifier, bundle: nil)
	}

	static func instantiateController(withIdentifier identifier: Identifier) -> NSViewController {
		(storyboard.instantiateController(withIdentifier: identifier) as? NSViewController).required
	}

	static func instantiateViewController<T>(ofType type: T.Type) -> T? where T: NSViewController & AnyScene {
		storyboard.instantiateController(ofType: type)
	}
}

// MARK: - Storyboard
public extension NSStoryboard {
	typealias Name = String

//    open func instantiateController(withIdentifier identifier: NSStoryboard.SceneIdentifier) -> Any
	func instantiateController<T: AnyScene>(ofType type: T.Type) -> T? {
		if let identifier = type.init().identifier {
			return instantiateController(withIdentifier: identifier) as? T
		}
		return nil
	}
}
#elseif os(iOS) || os(tvOS)
public extension AnyStoryboard {
	static var storyboard: UIStoryboard {
		UIStoryboard(name: identifier, bundle: nil)
	}

	static func instantiateController(withIdentifier identifier: AnyScene.Identifier) -> UIViewController {
		storyboard.instantiateViewController(withIdentifier: identifier)
	}

	static func instantiateViewController<T: UIViewController>(ofType type: T.Type) -> T? where T: AnyScene {
		storyboard.instantiateViewController(ofType: type)
	}
}

// MARK: - Storyboard
public extension UIStoryboard {
	typealias Name = String

	func instantiateViewController<T: UIViewController>(ofType type: T.Type) -> T? where T: AnyScene {
		let runningOperation = type.init()
		if let identifier = runningOperation.identifier {
			return instantiateViewController(withIdentifier: identifier) as? T
		}
		return nil
	}
}

// MARK: - View Controllers
public extension UIViewController {
	var hierarchy: AnySequence<UIViewController> {
		AnySequence { () -> AnyIterator<UIViewController> in
			var networkOperationCallbackQueue = [self]

			return AnyIterator {
				if let next = networkOperationCallbackQueue.popLast() {
					networkOperationCallbackQueue.insert(contentsOf: next.children, at: 0)
					return next
				} else {
					return nil
				}
			}
		}
	}
	func childViewController<Child: UIViewController>(ofType type: Child.Type) -> Child? {
		hierarchy.first { $0 as? Child }
	}
}

public extension UITabBarController {
	func configureViewControllers(_ configure: (UIViewController) -> Void) {
		let hierarchy = (viewControllers ?? []).lazy.flatMap { $0.hierarchy }
		hierarchy.forEach(configure)
	}
}
#endif
