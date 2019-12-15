//
//  Created by Marcin Krzyzanowski on 07/08/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//
//  Adjusted to the needs of specific projects by Robert Geifman in 2018
//

#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#endif
import Aspects

fileprivate extension Optional where Wrapped == String {
	var unwrappedStringValue: String {
		switch self {
		case .none: return "nil"
		case .some(let value): return "\(value)"
		}
	}
}

extension Sequence {
	func first<Result>(_ isMatch: (Iterator.Element) -> Result?) -> Result? {
		for element in self {
			if let result = isMatch(element) {
				return result
			}
		}
		return nil
	}
}

extension Collection {
	var second: Iterator.Element? {
		index(startIndex, offsetBy: 1, limitedBy: endIndex).map { self[$0] }
	}
}

#if os(macOS)
public protocol IdentifiableProtocol: Equatable {
	var storyboardIdentifier: NSStoryboard.SceneIdentifier? { get }
}
#else
public protocol IdentifiableProtocol: Equatable {
	var storyboardIdentifier: UIStoryboard.SceneIdentifier? { get }
}
#endif

#if os(macOS)
public protocol AnySegue {
	var identifier: NSStoryboardSegue.Identifier? { get }
	var kind: SegueKind { get }
	var type: NSViewController.Type { get }
}

public struct Segue<Destination: NSViewController>: AnySegue {
	public let identifier: NSStoryboardSegue.Identifier?
	public let kind: SegueKind
	public var type: NSViewController.Type { Destination.self }

	public init(_ identifier: NSStoryboardSegue.Identifier? = nil, kind: SegueKind) {
		self.identifier = identifier
		self.kind = kind
	}
}

public struct Reusable {
	public let identifier: String
	let kind: ReusableKind?
	let type: AnyObject.Type
	public init(_ identifier: String, _ kind: String, _ type: AnyObject.Type) {
		self.identifier = identifier
		self.kind = ReusableKind(rawValue: kind)
		self.type = type
	}
}

extension NSStoryboardSegue {
	@nonobjc
	public var matchPattern: (String?, String?, String?, Any, String?, String?, Any) {
		let source = sourceController as? NSUserInterfaceItemIdentification
		let destination = destinationController as? NSUserInterfaceItemIdentification
		let srcStoryboardID: String? = (source as? IdentifiableProtocol)?.storyboardIdentifier
		let dstStoryboardID: String? = (destination as? IdentifiableProtocol)?.storyboardIdentifier
		return (identifier, source?.identifier?.rawValue, srcStoryboardID.unwrappedStringValue, sourceController,
			destination?.identifier?.rawValue, dstStoryboardID.unwrappedStringValue, destinationController)
	}

	@nonobjc
	public final func destinationViewController<Destination: NSViewController>(ofType type: Destination.Type) -> Destination? {
		(destinationController as? NSViewController)?.childViewController(ofType: type)
	}
}

extension NSWindowController {
	internal var segueController: Any? { self }

	public func perform<Destination: NSViewController>(_ segue: AnySegue, prepare: @escaping (Destination) -> Void = { _ in }) {
		guard let identifier = segue.identifier else {
			assertionFailure("cannot perform segue \(segue.kind) with destination \(Destination.self) because it has no identifer")
			return
		}

		guard segue.type == Destination.self else {
			fatalError("\(segue.type) should be same as Destination (\(Destination.self))")
		}

		performSegue(withIdentifier: identifier) { [segueDescription = { String(reflecting: segue) }] segue, _ in
			guard let destination = segue.destinationViewController(ofType: Destination.self) else {
				fatalError("\(segueDescription()): expected destination view controller hierarchy to include \(Destination.self)")
			}

			prepare(destination)
		}
	}

// swiftlint:disable:next force_try
	internal func performSegue(withIdentifier identifier: String, sender: Any? = nil, prepare: @escaping (NSStoryboardSegue, Any?) -> Void) {
		_ = try! hookOnce(after :#selector(NSViewController.prepare(for:sender:))) { info in
			let arguments = info.arguments()!
			prepare(arguments.first as! NSStoryboardSegue, arguments.second)
		}

		performSegue(withIdentifier: identifier, sender: sender)
	}
}

extension NSViewController {
	internal var segueController: Any? { self }

	public func perform<Destination: NSViewController>(_ segue: AnySegue, prepare: @escaping (Destination) -> Void = { _ in }) {
		guard let identifier = segue.identifier else {
			assertionFailure("cannot perform segue \(segue.kind) with destination \(Destination.self) because it has no identifer")
			return
		}

		guard segue.type == Destination.self else {
			fatalError("\(segue.type) should be same as Destination (\(Destination.self))")
		}

		performSegue(withIdentifier: identifier) { [segueDescription = { String(reflecting: segue) }] segue, _ in
			guard let destination = segue.destinationViewController(ofType: Destination.self) else {
				fatalError("\(segueDescription()): expected destination view controller hierarchy to include \(Destination.self)")
			}

			prepare(destination)
		}
	}

	public func performOriginal<Destination>(_ segue: Segue<Destination>, prepare: @escaping (Destination) -> Void = { _ in }) {
		guard let identifier = segue.identifier else {
			assertionFailure("cannot perform segue \(segue.kind) with destination \(Destination.self) because it has no identifer")
			return
		}

		guard segue.type == Destination.self else {
			fatalError("\(segue.type) should be same as Destination (\(Destination.self))")
		}
		
		performSegue(withIdentifier: identifier) { [segueDescription = { String(reflecting: segue) }] segue, _ in
			guard let destination = segue.destinationViewController(ofType: Destination.self) else {
				fatalError("\(segueDescription()): expected destination view controller hierarchy to include \(Destination.self)")
			}

			prepare(destination)
		}
	}

// swiftlint:disable:next force_try
	internal func performSegue(withIdentifier identifier: String, sender: Any? = nil, prepare: @escaping (NSStoryboardSegue, Any?) -> Void) {
		_ = try! hookOnce(after :#selector(NSViewController.prepare(for:sender:))) { info in
			let arguments = info.arguments()!
			prepare(arguments.first as! NSStoryboardSegue, arguments.second)
		}

		performSegue(withIdentifier: identifier, sender: sender)
	}
}

extension NSViewController {
	public func childViewController<Child: NSViewController>(ofType type: Child.Type) -> Child? {
		hierarchy.first { $0 as? Child }
	}

	var hierarchy: AnySequence<NSViewController> {
		AnySequence { () -> AnyIterator<NSViewController> in
			var queue = [self]

			return AnyIterator {
				if let next = queue.popLast() {
					queue.insert(contentsOf: next.children, at: 0)
					return next
				} else {
					return nil
				}
			}
		}
	}
}

extension NSSplitViewController {
	public func configureViewControllers(_ configure: (NSViewController) -> Void) {
		let hierarchy = splitViewItems.lazy.flatMap { $0.viewController.hierarchy }
		hierarchy.forEach(configure)
	}
}
#elseif os(iOS)
public protocol AnySegue {
	var identifier: UIStoryboardSegue.Identifier? { get }
	var kind: SegueKind { get }
	var type: UIViewController.Type { get }
}

public struct Segue<Destination: UIViewController>: AnySegue {
	public let identifier: UIStoryboardSegue.Identifier?
	public let kind: SegueKind
	public var type: UIViewController.Type { Destination.self }

	public init(_ identifier: UIStoryboardSegue.Identifier? = nil, kind: SegueKind) {
		self.identifier = identifier
		self.kind = kind
	}
}

public struct Reusable {
	let identifier: String
	internal let kind: ReusableKind?
	internal let type: UIView.Type
	init(_ identifier: String, _ kind: String, _ type: UIView.Type) {
		self.identifier = identifier
		self.kind = ReusableKind(rawValue: kind)
		self.type = type
	}
}

public extension UIStoryboardSegue {
	@nonobjc
	final func destinationViewController<Destination: UIViewController>(ofType type: Destination.Type) -> Destination? {
		destination.childViewController(ofType: type)
	}
}

public extension UIViewController {
	internal var segueController: Any? { self }

	func perform<Destination>(_ segue: Segue<Destination>, prepare: @escaping (Destination) -> Void = { _ in }) {
		guard let segueIdentifier = segue.identifier else { runtimeError(in: self) }
		
		performSegue(withIdentifier: segueIdentifier) { [segueDescription = { String(reflecting: segue) }] segue, _ in
			guard let destination = segue.destinationViewController(ofType: Destination.self) else {
				fatalError("\(segueDescription()): expected destination view controller hierarchy to include \(Destination.self)")
			}

			prepare(destination)
		}
	}

// swiftlint:disable force_try
	internal func performSegue(withIdentifier identifier: String, sender: Any? = nil, prepare: @escaping (UIStoryboardSegue, Any?) -> Void) {
		_ = try! hookOnce(after: #selector(UIViewController.prepare(for:sender:))) { info in
			let arguments = info.arguments()!
			prepare(arguments.first as! UIStoryboardSegue, arguments.second)
		}

		performSegue(withIdentifier: identifier, sender: sender)
	}
// swiftlint:enable force_try
}

public extension UIViewController {
	@available(*, unavailable)
	func perform() {
		fatalError("This method will never be called, and exists only to remove an apparent ambiguity resolving the generic method 'perform(_:prepare:)'")
	}
}

extension UITabBarController {
  public func configureViewControllers(_ configure: (UIViewController) -> Void) {
    let hierarchy = (viewControllers ?? []).lazy.flatMap { $0.hierarchy }
    hierarchy.forEach(configure)
  }
}

extension UIViewController {
	public func childViewController<Child: UIViewController>(ofType type: Child.Type) -> Child? {
		hierarchy.first { $0 as? Child }
	}

	var hierarchy: AnySequence<UIViewController> {
		AnySequence { () -> AnyIterator<UIViewController> in
			var queue = [self]

			return AnyIterator {
				if let next = queue.popLast() {
					queue.insert(contentsOf: next.children, at: 0)
					return next
				} else {
					return nil
				}
			}
		}
	}
}
#endif

// MARK: - Storyboards
#if os(macOS)
public extension NSStoryboard {
	func instantiateViewController<T: NSWindowController>(ofType type: T.Type) -> T? where T: IdentifiableProtocol {
		let instance = type.init()
		if let identifier = instance.storyboardIdentifier {
			return instantiateController(withIdentifier: identifier) as? T
		}
		return nil
	}

	func instantiateViewController<T: NSViewController>(ofType type: T.Type) -> T? where T: IdentifiableProtocol {
		let instance = type.init()
		if let identifier = instance.storyboardIdentifier {
			return instantiateController(withIdentifier: identifier) as? T
		}
		return nil
	}
}
#else
public extension UIStoryboardSegue {
	typealias Identifier = String
}

public extension UIStoryboard {
	typealias Name = String
	typealias SceneIdentifier = String
	func instantiateViewController<T: UIViewController>(ofType type: T.Type) -> T? where T: IdentifiableProtocol {
		let instance = type.init()
		if let identifier = instance.storyboardIdentifier {
			return instantiateViewController(identifier: identifier) as? T
		}
		return nil
	}
}
#endif
protocol Storyboard {
#if os(macOS)
	static var storyboard: NSStoryboard { get }
	static var identifier: NSStoryboard.Name { get }
#else
	static var storyboard: UIStoryboard { get }
	static var identifier: UIStoryboard.Name { get }
#endif
	}

// MARK: - ReusableKind
public enum ReusableKind: String, CustomStringConvertible {
#if os(macOS)
	case tableCellView = "tableCellView"
	case collectionViewItem = "collectionViewItem"
#else
	case tableViewCell = "tableViewCell"
	case collectionViewCell = "collectionViewCell"
#endif
	public var description: String { rawValue }
}

// MARK: - SegueKind
public enum SegueKind: String, CustomStringConvertible {
	case relationship = "relationship"
	case show = "show"
	case sheet = "sheet"
	case presentation = "presentation"
	case embed = "embed"
	case unwind = "unwind"
	case push = "push"
	case modal = "modal"
	case popover = "popover"
	case replace = "replace"
	case custom = "custom"

	public var description: String { rawValue }
}

#if os(macOS)
extension Storyboard {
	static var storyboard: NSStoryboard {
		NSStoryboard(name: self.identifier, bundle: nil)
	}

	static func instantiateController(withIdentifier identifier: NSStoryboard.SceneIdentifier) -> NSWindowController {
		storyboard.instantiateController(withIdentifier: identifier) as! NSWindowController
	}

	static func instantiateViewController<T: NSWindowController>(ofType type: T.Type) -> T? where T: IdentifiableProtocol {
		storyboard.instantiateViewController(ofType: type)
	}

	static func instantiateController(withIdentifier identifier: NSStoryboard.SceneIdentifier) -> NSViewController {
		storyboard.instantiateController(withIdentifier: identifier) as! NSViewController
	}

	static func instantiateViewController<T: NSViewController>(ofType type: T.Type) -> T? where T: IdentifiableProtocol {
		storyboard.instantiateViewController(ofType: type)
	}
}

// MARK: - SegueProtocol
protocol SegueProtocol {
	var identifier: NSStoryboardSegue.Identifier? { get }
}

func ==<T: SegueProtocol>(lhs: T, rhs: NSStoryboardSegue.Identifier) -> Bool {
	lhs.identifier == rhs
}

func ~=<T: SegueProtocol>(lhs: T, rhs: NSStoryboardSegue.Identifier) -> Bool {
	lhs.identifier == rhs
}

func ==<T: SegueProtocol>(lhs: NSStoryboardSegue.Identifier, rhs: T) -> Bool {
	lhs == rhs.identifier
}

func ~=<T: SegueProtocol>(lhs: NSStoryboardSegue.Identifier, rhs: T) -> Bool {
	lhs == rhs.identifier
}

// MARK: - Protocol Implementation
extension NSStoryboardSegue: SegueProtocol {
}

// MARK: - NSViewController extension
extension NSViewController {
	func perform<T: SegueProtocol>(segue: T, sender: Any?) {
		if let identifier = segue.identifier {
			performSegue(withIdentifier: identifier, sender: sender)
		}
	}

	func perform<T: SegueProtocol>(segue: T) {
		perform(segue: segue, sender: nil)
	}
}

// MARK: - NSWindowController extension
extension NSWindowController {
	func perform<T: SegueProtocol>(segue: T, sender: Any?) {
		if let identifier = segue.identifier {
			performSegue(withIdentifier: identifier, sender: sender)
		}
	}

	func perform<T: SegueProtocol>(segue: T) {
		perform(segue: segue, sender: nil)
	}
}

#elseif os(iOS)
extension Storyboard {
	static var storyboard: UIStoryboard {
		UIStoryboard(name: self.identifier, bundle: nil)
	}

	static func instantiateController(withIdentifier identifier: UIStoryboard.SceneIdentifier) -> UIViewController {
		storyboard.instantiateViewController(identifier: identifier)
	}

	static func instantiateViewController<T: UIViewController>(ofType type: T.Type) -> T? where T: IdentifiableProtocol {
		storyboard.instantiateViewController(ofType: type)
	}
}

// MARK: - SegueProtocol
protocol SegueProtocol {
	var identifier: UIStoryboardSegue.Identifier? { get }
}

func ==<T: SegueProtocol>(lhs: T, rhs: UIStoryboardSegue.Identifier) -> Bool {
	lhs.identifier == rhs
}

func ~=<T: SegueProtocol>(lhs: T, rhs: UIStoryboardSegue.Identifier) -> Bool {
	lhs.identifier == rhs
}

func ==<T: SegueProtocol>(lhs: UIStoryboardSegue.Identifier, rhs: T) -> Bool {
	lhs == rhs.identifier
}

func ~=<T: SegueProtocol>(lhs: UIStoryboardSegue.Identifier, rhs: T) -> Bool {
	lhs == rhs.identifier
}

// MARK: - Protocol Implementation
extension UIStoryboardSegue: SegueProtocol {
}

// MARK: - UIViewController extension
extension UIViewController {
	func perform<T: SegueProtocol>(segue: T, sender: Any?) {
		if let identifier = segue.identifier {
			performSegue(withIdentifier: identifier, sender: sender)
		}
	}

	func perform<T: SegueProtocol>(segue: T) {
		perform(segue: segue, sender: nil)
	}
}
#endif

func ==<T: SegueProtocol, U: SegueProtocol>(lhs: T, rhs: U) -> Bool {
	lhs.identifier == rhs.identifier
}

func ~=<T: SegueProtocol, U: SegueProtocol>(lhs: T, rhs: U) -> Bool {
	lhs.identifier == rhs.identifier
}

// MARK: - ReusableViewProtocol
#if os(macOS)
protocol ReusableViewProtocol {
	var storyboardIdentifier: NSUserInterfaceItemIdentifier? { get }
	var viewType: NSView.Type? { get }
}

// MARK: - NSCollectionView
extension NSCollectionView {
	func dequeue<T: ReusableViewProtocol>(reusable: T, for indexPath: IndexPath) -> NSCollectionViewItem? {
		if let identifier = reusable.storyboardIdentifier {
			return makeItem(withIdentifier: identifier, for: indexPath)
		}
		return nil
	}

	func register<T: ReusableViewProtocol>(reusable: T) {
		if let type = reusable.viewType, let identifier = reusable.storyboardIdentifier {
			register(type, forItemWithIdentifier: identifier)
		}
	}

	func dequeueReusableView<T: ReusableViewProtocol>(ofKind elementKind: NSCollectionView.SupplementaryElementKind, reusable: T, for indexPath: IndexPath) -> NSView? {
		if let identifier = reusable.storyboardIdentifier {
			return makeSupplementaryView(ofKind: elementKind, withIdentifier: identifier, for: indexPath)
		}
		return nil
	}

	func registerReusableView<T: ReusableViewProtocol>(ofKind elementKind: NSCollectionView.SupplementaryElementKind, reusable: T) {
		if let type = reusable.viewType, let identifier = reusable.storyboardIdentifier {
			register(type, forSupplementaryViewOfKind: elementKind, withIdentifier: identifier)
		}
	}
}
// MARK: - NSTableView
extension NSTableView {
	func dequeue<T: ReusableViewProtocol>(reusable: T, for: IndexPath) -> NSView? {
		if let identifier = reusable.storyboardIdentifier {
			return makeView(withIdentifier: identifier, owner: nil)
		}
		return nil
	}

	func register<T: ReusableViewProtocol>(reusable: T, nibName: NSNib.Name, bundle bundleOrNil: Bundle?) {
		if let identifier = reusable.storyboardIdentifier,
			let nib = NSNib(nibNamed: nibName, bundle: bundleOrNil) {
			register(nib, forIdentifier: identifier)
		}
	}

	func register<T: ReusableViewProtocol>(reusable: T, nibData: Data, bundle bundleOrNil: Bundle?) {
		if let identifier = reusable.storyboardIdentifier {
			let nib = NSNib(nibData: nibData, bundle: bundleOrNil)
			register(nib, forIdentifier: identifier)
		}
	}
}

extension NSTableCellView: ReusableViewProtocol {
	public var viewType: NSView.Type? { type(of: self) }
	public var storyboardIdentifier: NSUserInterfaceItemIdentifier? { identifier }
}

extension NSTableHeaderView: ReusableViewProtocol {
	public var viewType: NSView.Type? { type(of: self) }
	public var storyboardIdentifier: NSUserInterfaceItemIdentifier? { identifier }
}

extension NSTableRowView: ReusableViewProtocol {
	public var viewType: NSView.Type? { type(of: self) }
	public var storyboardIdentifier: NSUserInterfaceItemIdentifier? { identifier }
}
#else
protocol ReusableViewProtocol: IdentifiableProtocol {
	var viewType: UIView.Type? { get }
}

// MARK: - UICollectionView
extension UICollectionView {
	func dequeue<T: ReusableViewProtocol>(reusable: T, for: IndexPath) -> UICollectionViewCell? {
		if let identifier = reusable.storyboardIdentifier {
			return dequeueReusableCell(withReuseIdentifier: identifier, for: `for`)
		}
		return nil
	}

	func register<T: ReusableViewProtocol>(reusable: T) {
		if let type = reusable.viewType, let identifier = reusable.storyboardIdentifier {
			register(type, forCellWithReuseIdentifier: identifier)
		}
	}

	func dequeueReusableSupplementaryViewOfKind<T: ReusableViewProtocol>(elementKind: String, withReusable reusable: T, for: IndexPath) -> UICollectionReusableView? {
		if let identifier = reusable.storyboardIdentifier {
			return dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for: `for`)
		}
		return nil
	}

	func register<T: ReusableViewProtocol>(reusable: T, forSupplementaryViewOfKind elementKind: String) {
		if let type = reusable.viewType, let identifier = reusable.storyboardIdentifier {
			register(type, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
		}
	}
}
// MARK: - UITableView
extension UITableView {
	func dequeue<T: ReusableViewProtocol>(reusable: T, for: IndexPath) -> UITableViewCell? {
		if let identifier = reusable.storyboardIdentifier {
			return dequeueReusableCell(withIdentifier: identifier, for: `for`)
		}
		return nil
	}

	func register<T: ReusableViewProtocol>(reusable: T) {
		if let type = reusable.viewType, let identifier = reusable.storyboardIdentifier {
			register(type, forCellReuseIdentifier: identifier)
		}
	}

	func dequeueReusableHeaderFooter<T: ReusableViewProtocol>(_ reusable: T) -> UITableViewHeaderFooterView? {
		if let identifier = reusable.storyboardIdentifier {
			return dequeueReusableHeaderFooterView(withIdentifier: identifier)
		}
		return nil
	}

	func registerReusableHeaderFooter<T: ReusableViewProtocol>(_ reusable: T) {
		if let type = reusable.viewType, let identifier = reusable.storyboardIdentifier {
			 register(type, forHeaderFooterViewReuseIdentifier: identifier)
		}
	}
}

extension UITableViewCell: ReusableViewProtocol {
	public var viewType: UIView.Type? { type(of: self) }
	public var storyboardIdentifier: String? { reuseIdentifier }
}

extension UICollectionReusableView: ReusableViewProtocol {
	public var viewType: UIView.Type? { type(of: self) }
	public var storyboardIdentifier: String? { reuseIdentifier }
}
#endif // os(iOS)

func ==<T: ReusableViewProtocol, U: ReusableViewProtocol>(lhs: T, rhs: U) -> Bool {
	lhs.storyboardIdentifier == rhs.storyboardIdentifier
}

