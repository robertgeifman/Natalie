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

// MARK: - ReusableKind
public enum ReusableKind: ExpressibleByStringLiteral {
#if os(macOS)
	case tableCellView
	case collectionViewItem
	case collectionSupplementaryView(elementKind: String)
	public init(stringLiteral: String) {
		self = .collectionSupplementaryView(elementKind: stringLiteral)
	}
#else
	case tableViewCell
	case tableHeaderFooterView
	case collectionViewCell
	case collectionReusableView(elementKind: String)
	public init(stringLiteral: String) {
		self = .collectionReusableView(elementKind: stringLiteral)
	}
#endif
}

public protocol ReusableViewProtocol: AnyScene {
#if os(iOS) || os(tvOS)
	var viewType: UIView.Type? { get }
#elseif os(macOS)
	var viewType: NSView.Type? { get }
#endif
}

public func ==<T: ReusableViewProtocol, U: ReusableViewProtocol>(lhs: T, rhs: U) -> Bool {
	lhs.identifier == rhs.identifier
}

// MARK: - ReusableProtocol
public protocol ReusableProtocol: CustomStringConvertible {
	var identifier: String { get }
	var kind: ReusableKind { get }
}

public extension ReusableProtocol {
	var elementKind: String {
		switch kind {
#if os(macOS)
		case .tableCellView: return "tableCellView"
		case .collectionViewItem: return "collectionViewItem"
		case .collectionSupplementaryView(let kind): return kind
#else
		case .collectionReusableView(let kind): return kind
		case .collectionViewCell: return "collectionViewCell"
		case .tableViewCell: return "tableViewCell"
		case .tableHeaderFooterView: return "tableHeaderFooterView"
#endif
		}
	}
	var description: String {
		switch kind {
#if os(macOS)
		case .tableCellView:
			return "tableCellView\(identifier))"
		case .collectionViewItem:
			return "collectionViewItem\(identifier))"
		case .collectionSupplementaryView(let kind): return "collectionSupplementaryView\(identifier), elementKind: \(kind)"
#else
		case .collectionReusableView(let kind):
			return "collectionReusableView(\(identifier), elementKind: \(kind))"
		case .collectionViewCell:
			return "collectionViewCell(\(identifier))"
		case .tableViewCell:
			return "tableViewCell(\(identifier))"
		case .tableHeaderFooterView:
			return "tableHeaderFooterView(\(identifier))"
#endif
		}
	}
}

// MARK: - Reusable
#if os(macOS)
public struct Reusable<Content>: ReusableProtocol, CustomStringConvertible {
	public let identifier: String
	public let kind: ReusableKind

	public init(_ identifier: String) where Content: NSCollectionViewItem {
		self.identifier = identifier
		self.kind = .collectionViewItem
	}
	public init(_ identifier: String, elementKind: String) where Content: NSView {
		self.identifier = identifier
		self.kind = .collectionSupplementaryView(elementKind: elementKind)
	}
}
#else
public struct Reusable<Content: UIView>: ReusableProtocol, CustomStringConvertible {
	public let identifier: String
	public let kind: ReusableKind

	public init(_ identifier: String, kind: ReusableKind) {
		self.identifier = identifier
		self.kind = kind
	}
	public init(_ identifier: String) where Content: UICollectionViewCell {
		self.identifier = identifier
		self.kind = .collectionViewCell
	}
	public init(_ identifier: String) where Content: UITableViewCell {
		self.identifier = identifier
		self.kind = .tableViewCell
	}
	public init(_ identifier: String) where Content: UITableViewHeaderFooterView {
		self.identifier = identifier
		self.kind = .tableHeaderFooterView
	}
	@_disfavoredOverload
	public init(_ identifier: String, elementKind: String) where Content: UICollectionReusableView {
		self.identifier = identifier
		self.kind = .collectionReusableView(elementKind: elementKind)
	}
	public init(header identifier: String) where Content: UICollectionReusableView {
		self.identifier = identifier
		self.kind = .collectionReusableView(elementKind: UICollectionView.elementKindSectionHeader)
	}
	public init(footer identifier: String) where Content: UICollectionReusableView {
		self.identifier = identifier
		self.kind = .collectionReusableView(elementKind: UICollectionView.elementKindSectionFooter)
	}
}
#endif

// MARK: - Reusable - Cell
#if os(macOS)
public extension Reusable where Content: NSCollectionViewItem {
	func configure<Data>(using body: @escaping (Data, Content) -> Void) -> (IndexPath, NSCollectionView, Data?) -> Content {
		return { indexPath, collectionView, data in
			self.dequeue(at: indexPath, in: collectionView) {
				if let data = data { body(data, $0) }
			}
		}
	}
	func dequeue(at indexPath: IndexPath, in collectionView: NSCollectionView, body: (Content) -> Void = { _ in }) -> Content {
		guard let view = collectionView.makeItem(withIdentifier: identifier, for: indexPath) as? Content else { runtimeError() }
		body(view)
		return view
	}
}

// MARK: - Reusable- DecorationView
public extension Reusable where Content: NSView {
	func configure<Data>(elementKind: String, using body: @escaping (Data, Content) -> Void) -> (IndexPath, NSCollectionView, Data?) -> Content {
		return { indexPath, collectionView, data in
			self.dequeue(for: elementKind, at: indexPath, in: collectionView) {
				if let data = data { body(data, $0) }
			}
		}
	}
	func dequeue(for elementKind: String, at indexPath: IndexPath, in collectionView: NSCollectionView, body: (Content) -> Void = { _ in }) -> Content {
		guard let view = collectionView.makeSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for: indexPath) as? Content else { runtimeError() }
		body(view)
		return view
	}
}
#else
public extension Reusable where Content: UICollectionViewCell {
	func configure<Data>(using body: @escaping (Data, Content) -> Void) -> (IndexPath, UICollectionView, Data?) -> Content {
		return { indexPath, collectionView, data in
			self.dequeue(at: indexPath, in: collectionView) {
				if let data = data { body(data, $0) }
			}
		}
	}
	func dequeue(at indexPath: IndexPath, in collectionView: UICollectionView, body: (Content) -> Void = { _ in }) -> Content {
		guard let view = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? Content else { runtimeError() }
		body(view)
		return view
	}
}

// MARK: - Reusable- DecorationView
public extension Reusable where Content: UICollectionReusableView {
	func configure<Data>(elementKind: String, using body: @escaping (Data, Content) -> Void) -> (IndexPath, UICollectionView, Data?) -> Content {
		return { indexPath, collectionView, data in
			self.dequeue(for: elementKind, at: indexPath, in: collectionView) {
				if let data = data { body(data, $0) }
			}
		}
	}
	func dequeue(for elementKind: String, at indexPath: IndexPath, in collectionView: UICollectionView, body: (Content) -> Void = { _ in }) -> Content {
		guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for: indexPath) as? Content else { runtimeError() }
		body(view)
		return view
	}
}

// MARK: - Reusable - Cell
public extension Reusable where Content: UITableViewCell {
	func configure<Data>(using body: @escaping (Data, Content) -> Void) -> (IndexPath, UITableView, Data?) -> Content {
		return { indexPath, tableView, data in
			self.dequeue(at: indexPath, in: tableView) {
				if let data = data { body(data, $0) }
			}
		}
	}
	func dequeue(at indexPath: IndexPath, in tableView: UITableView, body: (Content) -> Void = { _ in }) -> Content {
		guard let view = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? Content else { runtimeError() }
		body(view)
		return view
	}
}

// MARK: - Reusable- DecorationView
public extension Reusable where Content: UITableViewHeaderFooterView {
	func configure<Data>(elementKind: String, using body: @escaping (Data, Content) -> Void) -> (IndexPath, UITableView, Data?) -> Content {
		return { indexPath, tableView, data in
			self.dequeue(in: tableView) {
				if let data = data { body(data, $0) }
			}
		}
	}
	func dequeue(in tableView: UITableView, body: (Content) -> Void = { _ in }) -> Content {
		guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) as? Content else { runtimeError() }
		body(view)
		return view
	}
}
#endif
