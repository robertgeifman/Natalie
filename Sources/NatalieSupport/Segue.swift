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

// MARK: - SegueKind
public enum SegueKind: CustomStringConvertible {
	case relationship
	case show
	case showDetail
	case sheet
	case presentation
	case embed
	case unwind
	case push
	case modal
	case popover
	case replace
	case custom
	// case custom(UIStoryboardSegue.Type)

	public var description: String {
		switch self {
		case .relationship: return "relationship"
		case .show: return "show"
		case .showDetail: return "showDetail"
		case .sheet: return "sheet"
		case .presentation: return "presentation"
		case .embed: return "embed"
		case .unwind: return "unwind"
		case .push: return "push"
		case .modal: return "modal"
		case .popover: return "popover"
		case .replace: return "replace"
		case .custom: return "custom"
		// case .custom(let type): return "custom(\(type.self))"
		}
	}
}

public enum TypedSegueError: LocalizedError {
#if os(iOS) || os(tvOS)
	case castToCustomClass(UIStoryboardSegue.Type)
#elseif os(macOS)
	case castToCustomClass(NSStoryboardSegue.Type)
#endif
}

// MARK: - SegueProtocol
public protocol SegueProtocol {
#if os(macOS)
	typealias Identifier = NSStoryboardSegue.Identifier
#elseif os(iOS) || os(tvOS)
	typealias Identifier = String
#endif
	var identifier: TypedSegue.Identifier? { get }
}

public func ==<T: SegueProtocol>(lhs: T, rhs: TypedSegue.Identifier) -> Bool {
	lhs.identifier == rhs
}

public func ~=<T: SegueProtocol>(lhs: T, rhs: TypedSegue.Identifier) -> Bool {
	lhs.identifier == rhs
}

public func ==<T: SegueProtocol>(lhs: TypedSegue.Identifier, rhs: T) -> Bool {
	lhs == rhs.identifier
}

public func ~=<T: SegueProtocol>(lhs: TypedSegue.Identifier, rhs: T) -> Bool {
	lhs == rhs.identifier
}

public func ==<T: SegueProtocol, U: SegueProtocol>(lhs: T, rhs: U) -> Bool {
	lhs.identifier == rhs.identifier
}

public func ~=<T: SegueProtocol, U: SegueProtocol>(lhs: T, rhs: U) -> Bool {
	lhs.identifier == rhs.identifier
}

// MARK: - TypedSegue
#if os(macOS)
public protocol TypedSegue: SegueProtocol {
	associatedtype Kind: NSStoryboardSegue
	associatedtype To: NSViewController
	var identifier: Identifier? { get }

	func perform(from source: NSViewController)
	func perform(from source: NSViewController, prepare body: @escaping (Kind, To) -> Void)
}

public extension TypedSegue {
	@_transparent
	func callAsFunction(from source: NSViewController) {
		perform(from: source)
	}
	@_transparent
	func callAsFunction(from source: NSViewController, prepare body: @escaping (Kind, To) -> Void) {
		perform(from: source, prepare: body)
	}
}

public extension TypedSegue where Kind == NSStoryboardSegue {
	func perform(from source: NSViewController, prepare body: @escaping (To) -> Void) {
		perform(from: source) { body($1) }
	}
	@_transparent
	func callAsFunction(from source: NSViewController, prepare body: @escaping (To) -> Void) {
		perform(from: source, prepare: body)
	}
}

// MARK: - Segue
public struct Segue<Kind, To>: TypedSegue
	where Kind: NSStoryboardSegue, To: NSViewController {
	public let identifier: TypedSegue.Identifier?

	public init(identifier: TypedSegue.Identifier?) {
		self.identifier = identifier
	}

	@_transparent
	func typedSegue(for segue: NSStoryboardSegue) -> Kind { (segue as? Kind).required }
}

public extension Segue {
	@_transparent
	func perform(from source: NSViewController) {
		source.performSegue(withIdentifier: identifier.required, sender: source)
	}

	func perform(from source: NSViewController, prepare body: @escaping (Kind, To) -> Void) {
		source.performSegue(withIdentifier: identifier.required) { [segueDescription = { String(reflecting: self) }] segue, _ in
			let destination = segue.destination(ofType: To.self)
				.require("\(segueDescription()): expected destination view controller hierarchy to include \(To.self)")
			let typedSegue = (segue as? Kind).required
			body(typedSegue, destination)
		}
	}
}

public extension NSViewController {
	var _sceneCoordinator: Any? { self }
	func perform() {
		rejectUnusedImplementation("This method will never be called, and exists only to remove an apparent ambiguity resolving the generic method 'perform(_:prepare:)'", in: self)
	}
	
	func performSegue(withIdentifier identifier: String, sender: Any? = nil, prepare body: @escaping (NSStoryboardSegue, Any?) -> Void) {
		do {
			_ = try hookOnce(after: #selector(NSViewController.prepare(for:sender:))) {
				guard let arguments = $0.arguments(),
					let segue = arguments.first as? NSStoryboardSegue else { runtimeError(in: self) }
				body(segue, arguments.second)
			}
			performSegue(withIdentifier: identifier, sender: sender)
		} catch {
			runtimeError(error, in: self)
		}
	}
}

public extension NSStoryboardSegue {
	@nonobjc @inline(__always)
	final var matchPattern: (String?,
		// String?,
		NSViewController.Type) {
		// guard let source = source, let destination = destination else { return (nil, nil, NSViewController.self, nil, NSViewController.self) }
		
		// let srcStoryboardID: String? = (source as? AnyScene)?.identifier
		// let dstStoryboardID: String? = (destination as? AnyScene)?.identifier
		return (identifier,
			// srcStoryboardID.unwrappedString,
			// type(of: sourceController),
			// dstStoryboardID.unwrappedString,
			type(of: destinationController))
	}

	@nonobjc
	final func destination<T>(ofType type: T.Type) -> T?
		where T: NSViewController {
		destination.childViewController(ofType: type)
	}
}

// MARK: - Protocol Implementation
extension NSStoryboardSegue: SegueProtocol {
	public var sourceController: NSViewController { source }
	public var destinationController: NSViewController { destination }
}
#elseif os(iOS) || os(tvOS)
public protocol TypedSegue: SegueProtocol {
	associatedtype Kind: UIStoryboardSegue
	associatedtype To: UIViewController
	var identifier: Identifier? { get }

	func perform(from source: UIViewController)
	func perform(from source: UIViewController, prepare body: @escaping (Kind, To) -> Void)
}

public extension TypedSegue {
	@_transparent
	func callAsFunction(from source: UIViewController) {
		perform(from: source)
	}
	@_transparent
	func callAsFunction(from source: UIViewController, prepare body: @escaping (Kind, To) -> Void) {
		perform(from: source, prepare: body)
	}
}

public extension TypedSegue where Kind == UIStoryboardSegue {
	func perform(from source: UIViewController, prepare body: @escaping (To) -> Void) {
		perform(from: source) { body($1) }
	}
	@_transparent
	func callAsFunction(from source: UIViewController, prepare body: @escaping (To) -> Void) {
		perform(from: source, prepare: body)
	}
}

// MARK: - Segue
public struct Segue<Kind, To>: TypedSegue
	where Kind: UIStoryboardSegue, To: UIViewController {
	public let identifier: TypedSegue.Identifier?

	public init(identifier: TypedSegue.Identifier?) {
		self.identifier = identifier
	}

	@_transparent
	func typedSegue(for segue: UIStoryboardSegue) -> Kind { (segue as? Kind).required }
}

public extension Segue {
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
}

public extension UIViewController {
	var _sceneCoordinator: Any? { self }
	func perform() {
		rejectUnusedImplementation("This method will never be called, and exists only to remove an apparent ambiguity resolving the generic method 'perform(_:prepare:)'", in: self)
	}
	
	func performSegue(withIdentifier identifier: String, sender: Any? = nil, prepare body: @escaping (UIStoryboardSegue, Any?) -> Void) {
		do {
			_ = try hookOnce(after: #selector(UIViewController.prepare(for:sender:))) { 
				guard let arguments = $0.arguments(),
					let segue = arguments.first as? UIStoryboardSegue else { runtimeError(in: self) }
				body(segue, arguments.second)
			}
			performSegue(withIdentifier: identifier, sender: sender)
		} catch {
			runtimeError(error, in: self)
		}
	}
}

public extension UIStoryboardSegue {
	@nonobjc @inline(__always)
	final var matchPattern: (String?,
		// String?,
		UIViewController.Type) {
		// guard let source = source, let destination = destination else { return (nil, nil, UIViewController.self, nil, UIViewController.self) }
		
		// let srcStoryboardID: String? = (source as? AnyScene)?.identifier
		// let dstStoryboardID: String? = (destination as? AnyScene)?.identifier
		return (identifier,
			// srcStoryboardID.unwrappedString,
			// type(of: sourceController),
			// dstStoryboardID.unwrappedString,
			type(of: destinationController))
	}

	@nonobjc
	final func destination<T>(ofType type: T.Type) -> T?
		where T: UIViewController {
		destination.childViewController(ofType: type)
	}
}

// MARK: - Protocol Implementation
extension UIStoryboardSegue: SegueProtocol {
	public var sourceController: UIViewController { source }
	public var destinationController: UIViewController { destination }
}
#endif
