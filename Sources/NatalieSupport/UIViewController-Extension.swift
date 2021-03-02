//
//  Swift Class.swift
//  
//
//  Created by Robert Geifman on 22/10/2020.
//  
//

#if os(iOS) || os(tvOS)
import UIKit

// MARK: - UIKit
public extension UIViewController {
	@inline(__always)
	func perform<Kind, To>(_ segue: Segue<Kind, To>)
		where Kind: UIStoryboardSegue, To: UIViewController { segue.perform(from: self) }
	@inline(__always)
	func perform<Kind, To>(_ segue: Segue<Kind, To>, prepare body: @escaping (Kind, To) -> Void)
		where Kind: UIStoryboardSegue, To: UIViewController {
		segue.perform(from: self, prepare: body)
	}
	@inline(__always)
	func perform<To>(_ segue: Segue<UIStoryboardSegue, To>)
		where To: UIViewController {
		segue.perform(from: self)
	}
	@inline(__always)
	func perform<To>(_ segue: Segue<UIStoryboardSegue, To>, prepare body: @escaping (To) -> Void)
		where To: UIViewController {
		segue.perform(from: self, prepare: body)
	}

	@inline(__always)
	func perform<Kind, To, Root>(_ segue: NavigationSegue<Kind, To, Root>)
		where Kind: UIStoryboardSegue, To: UINavigationController, Root: UIViewController {
		segue.perform(from: self)
	}
	@inline(__always)
	func perform<Kind, To, Root>(_ segue: NavigationSegue<Kind, To, Root>, prepare body: @escaping (Kind, To, Root) -> Void)
		where Kind: UIStoryboardSegue, To: UINavigationController, Root: UIViewController {
		segue.perform(from: self, prepare: body)
	}
	@inline(__always)
	func perform<To, Root>(_ segue: NavigationSegue<UIStoryboardSegue, To, Root>, prepare body: @escaping (To, Root) -> Void)
		where To: UINavigationController, Root: UIViewController {
		segue.perform(from: self) { body($1, $2) }
	}

	@inline(__always)
	func perform<Kind, To, Root>(_ segue: NavigationSegue<Kind, To, Root>, prepare body: @escaping (Kind, Root) -> Void)
		where Kind: UIStoryboardSegue, To: UINavigationController, Root: UIViewController {
		segue.perform(from: self) { body($0, $2) }
	}
	@inline(__always)
	func perform<To, Root>(_ segue: NavigationSegue<UIStoryboardSegue, To, Root>, prepare body: @escaping (Root) -> Void)
		where To: UINavigationController, Root: UIViewController {
		segue.perform(from: self) { body($2) }
	}
}
#endif
