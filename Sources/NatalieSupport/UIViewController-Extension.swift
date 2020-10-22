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
	func perform<Kind: UIStoryboardSegue, To: UIViewController>(_ segue: Segue<Kind, To>) { segue.perform(from: self) }
	@inline(__always)
	func perform<Kind: UIStoryboardSegue, To: UIViewController>(_ segue: Segue<Kind, To>, prepare body: @escaping (Kind, To) -> Void) {
		segue.perform(from: self, prepare: body)
	}
	@inline(__always)
	func perform<To: UIViewController>(_ segue: Segue<UIStoryboardSegue, To>) {
		segue.perform(from: self)
	}
	@inline(__always)
	func perform<To: UIViewController>(_ segue: Segue<UIStoryboardSegue, To>, prepare body: @escaping (To) -> Void) {
		segue.perform(from: self, prepare: body)
	}
	@inline(__always)
	func perform<Kind, To, Root>(_ segue: NavigationSegue<Kind, To, Root>)
		where Kind: UIStoryboardSegue, To: UINavigationController, Root: UIViewController {
		segue.perform(from: self)
	}
	@inline(__always)
	func perform<Kind, To, Root>(_ segue: NavigationSegue<Kind, To, Root>, prepare body: @escaping (Kind, To) -> Void)
		where Kind: UIStoryboardSegue, To: UINavigationController, Root: UIViewController {
		segue.perform(from: self) { kind, to, _ in body(kind, to) }
	}
	@inline(__always)
	func perform<Kind, To, Root>(_ segue: NavigationSegue<Kind, To, Root>, prepare body: @escaping (Kind, To, Root) -> Void)
		where Kind: UIStoryboardSegue, To: UINavigationController, Root: UIViewController {
		segue.perform(from: self, prepare: body)
	}
	@inline(__always)
	func perform<To, Root>(_ segue: NavigationSegue<UIStoryboardSegue, To, Root>, prepare body: @escaping (To) -> Void)
		where To: UINavigationController, Root: UIViewController {
		segue.perform(from: self) { _, to, _ in body(to) }
	}
	@inline(__always)
	func perform<To, Root>(_ segue: NavigationSegue<UIStoryboardSegue, To, Root>, prepare body: @escaping (To, Root) -> Void)
		where To: UINavigationController, Root: UIViewController {
		segue.perform(from: self) { body($1, $2) }
	}
}
#endif
