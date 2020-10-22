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
import Aspects

#if os(iOS) || os(tvOS)
// MARK: - NavigationSegue
public struct NavigationSegue<Kind, To, Root>: TypedSegue
	where Kind: UIStoryboardSegue, To: UINavigationController, Root: UIViewController {
	public let identifier: TypedSegue.Identifier?

	public init(identifier: TypedSegue.Identifier?) {
		self.identifier = identifier
	}

	public func perform(from source: UIViewController, prepare body: @escaping (Kind, To, Root) -> Void) {
		source.performSegue(withIdentifier: identifier.required) { [segueDescription = { String(reflecting: self) }] segue, _ in
			let destination = segue.destination(ofType: To.self)
				.require("\(segueDescription()): expected destination view controller hierarchy to include \(To.self)")
			let typedSegue = (segue as? Kind).required
			let root = destination.childViewController(ofType: Root.self).required
			body(typedSegue, destination, root)
		}
	}
	public func perform(from source: UIViewController, prepare body: @escaping (To, Root) -> Void)
		where Kind == UIStoryboardSegue {
		source.performSegue(withIdentifier: identifier.required) { [segueDescription = { String(reflecting: self) }] segue, _ in
			let destination = segue.destination(ofType: To.self)
				.require("\(segueDescription()): expected destination view controller hierarchy to include \(To.self)")
			let root = destination.childViewController(ofType: Root.self).required
			body(destination, root)
		}
	}
}

public extension NavigationSegue {
	@_transparent
	func perform(from source: UIViewController) {
		source.performSegue(withIdentifier: identifier.required, sender: source)
	}
	func perform(from source: UIViewController, prepare body: @escaping (Kind, To) -> Void) {
		source.performSegue(withIdentifier: identifier.required) { [segueDescription = { String(reflecting: self) }] segue, _ in
			let destination = segue.destination(ofType: To.self)
				.require("\(segueDescription()): expected destination view controller hierarchy to include \(To.self)")
			let typedSegue = (segue as? Kind).required
			body(typedSegue, destination)
		}
	}
	func perform(from source: UIViewController, prepare body: @escaping (To) -> Void)
		where Kind == UIStoryboardSegue{
		source.performSegue(withIdentifier: identifier.required) { [segueDescription = { String(reflecting: self) }] segue, _ in
			let destination = segue.destination(ofType: To.self)
				.require("\(segueDescription()): expected destination view controller hierarchy to include \(To.self)")
			body(destination)
		}
	}
}
#endif
