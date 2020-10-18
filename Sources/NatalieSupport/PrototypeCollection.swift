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
// MARK: - PrototypeCollection
public protocol CollectionViewPrototypes {
	subscript<Content>(reusable: Reusable<Content>) -> Content
		where Content: UICollectionViewCell { get }
	subscript<Content>(reusable: Reusable<Content>) -> Content
		where Content: UICollectionReusableView { get }
}
public protocol TableViewPrototypes {
	subscript<Content>(reusable: Reusable<Content>) -> Content
		where Content: UITableViewCell { get }
	subscript<Content>(reusable: Reusable<Content>) -> Content
		where Content: UITableViewHeaderFooterView { get }
}
#else
// MARK: - PrototypeCollection
public protocol CollectionViewPrototypes {
	subscript<Content>(reusable: Reusable<Content>) -> Content
		where Content: NSCollectionViewItem { get }
	subscript<Content>(reusable: Reusable<Content>) -> Content
		where Content: NSView { get }
}
#endif
