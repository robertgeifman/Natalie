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

#if os(iOS) || os(tvOS)
// MARK: - CollectionViewPrototypes
public protocol CollectionViewPrototypes {
	static var cells: [ReusableProtocol] { get }
	static var reusableViews: [ReusableProtocol] { get }
	var cells: [String: UICollectionViewCell] { get }
	var reusableViews: [String: UICollectionReusableView] { get }
	
	func makePrototypes(collectionView: UICollectionView) -> ([String: UICollectionViewCell], [String: UICollectionReusableView])

	subscript<T: UICollectionViewCell>(reusable: Reusable<T>) -> T { get }
	subscript<T: UICollectionReusableView>(reusable: Reusable<T>) -> T { get }
}

public extension CollectionViewPrototypes {
	typealias Kind = UICollectionView

	func makePrototypes(collectionView: UICollectionView) -> ([String: UICollectionViewCell], [String: UICollectionReusableView]) {
		var cells = [String: UICollectionViewCell]()
		var reusableViews = [String: UICollectionReusableView]()
		for reusable in Self.cells {
			cells[reusable.identifier] = collectionView.dequeueReusableCell(withReuseIdentifier: reusable.identifier, for: IndexPath())
		}
		for reusable in Self.reusableViews {
			reusableViews[reusable.identifier] = collectionView.dequeueReusableSupplementaryView(
				ofKind: reusable.elementKind, withReuseIdentifier: reusable.identifier, for: IndexPath())
		}
		return (cells, reusableViews)
	}
	
	@inline(__always)
	subscript<Content>(reusable: Reusable<Content>) -> Content
		where Content: UICollectionViewCell {
		(cells[reusable.identifier] as? Content).require("No prorotype for \(reusable)")
	}
	@inline(__always)
	subscript<Content>(reusable: Reusable<Content>) -> Content
		where Content: UICollectionReusableView {
		(reusableViews[reusable.identifier] as? Content).require("No prorotype for \(reusable)")
	}
}

// MARK: - TableViewPrototypes
public protocol TableViewPrototypes {
	static var cells: [ReusableProtocol] { get }
	static var reusableViews: [ReusableProtocol] { get }
	var cells: [String: UITableViewCell] { get }
	var reusableViews: [String: UITableViewHeaderFooterView] { get }
	
	func makePrototypes(tableView: UITableView) -> ([String: UITableViewCell], [String: UITableViewHeaderFooterView])

	subscript<T: UITableViewCell>(reusable: Reusable<T>) -> T { get }
	subscript<T: UITableViewHeaderFooterView>(reusable: Reusable<T>) -> T { get }
}

public extension TableViewPrototypes {
	typealias Kind = UITableView

	func makePrototypes(tableView: UITableView) -> ([String: UITableViewCell], [String: UITableViewHeaderFooterView]) {
		var cells = [String: UITableViewCell]()
		var reusableViews = [String: UITableViewHeaderFooterView]()
		for reusable in Self.cells {
			cells[reusable.identifier] = tableView.dequeueReusableCell(withIdentifier: reusable.identifier, for: IndexPath())
		}
		for reusable in Self.reusableViews {
			reusableViews[reusable.identifier] = tableView.dequeueReusableHeaderFooterView(withIdentifier: reusable.identifier)
		}
		return (cells, reusableViews)
	}
	
	@inline(__always)
	subscript<Content>(reusable: Reusable<Content>) -> Content
		where Content: UITableViewCell {
		(cells[reusable.identifier] as? Content).require("No prorotype for \(reusable)")
	}
	@inline(__always)
	subscript<Content>(reusable: Reusable<Content>) -> Content
		where Content: UITableViewHeaderFooterView {
		(reusableViews[reusable.identifier] as? Content).require("No prorotype for \(reusable)")
	}
}
#else
// MARK: - PrototypeCollection
public protocol CollectionViewPrototypes {
	subscript<T: NSCollectionViewItem>(reusable: Reusable<T>) -> T { get }
	subscript<T: NSView>(reusable: Reusable<T>) -> T { get }
}
#endif
