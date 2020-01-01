//
//  OS.swift
//  Natalie
//
//  Created by Marcin Krzyzanowski on 07/08/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

enum OS: String, CustomStringConvertible {
    case iOS = "iOS"
    case OSX = "OSX"
    case tvOS = "tvOS"

    static let allValues = [iOS, OSX, tvOS]

    enum Runtime: String {
        case iOSCocoaTouch = "iOS.CocoaTouch"
        case MacOSXCocoa = "MacOSX.Cocoa"
        case AppleTV = "AppleTV"

        init(os: OS) {
            switch os {
            case iOS: self = .iOSCocoaTouch
            case OSX: self = .MacOSXCocoa
            case tvOS: self = .AppleTV
            }
        }
    }

    enum Framework: String {
        case UIKit = "UIKit"
        case Cocoa = "Cocoa"

        init(os: OS) {
            switch os {
            case iOS, .tvOS: self = .UIKit
            case OSX: self = .Cocoa
            }
        }
    }

    init(targetRuntime: String) {
        switch targetRuntime {
        case Runtime.iOSCocoaTouch.rawValue: self = .iOS
        case Runtime.MacOSXCocoa.rawValue: self = .OSX
        case Runtime.AppleTV.rawValue: self = .tvOS
        case "iOS.CocoaTouch.iPad": self = .iOS
        default:
        	fatalError("Unsupported \(targetRuntime)")
        }
    }

    var description: String {
        return self.rawValue
    }

    var framework: String {
        return Framework(os: self).rawValue
    }

    var targetRuntime: String {
        return Runtime(os: self).rawValue
    }

    var storyboardType: String {
        switch self {
        case .iOS, .tvOS: return "UIStoryboard"
        case .OSX: return "NSStoryboard"
        }
    }

    var storyboardIdentifierType: String {
        switch self {
        case .iOS, .tvOS: return "String"
        case .OSX: return "NSStoryboard.Name"
        }
    }

    var storyboardSceneIdentifierType: String {
        switch self {
        case .iOS, .tvOS: return "String"
        case .OSX: return "NSStoryboard.SceneIdentifier"
        }
    }

    var storyboardSegueType: String {
        switch self {
        case .iOS, .tvOS: return "UIStoryboardSegue"
        case .OSX: return "NSStoryboardSegue"
        }
    }

    var segueDestinationController: String {
        switch self {
        case .iOS, .tvOS: return "destination"
        case .OSX: return "destinationContoller"
        }
    }

    var storyboardSegueIdentifierType: String {
        switch self {
        case .iOS, .tvOS: return "String"
        case .OSX: return "NSStoryboardSegue.Identifier"
        }
    }

    var storyboardControllerTypes: [String] {
        switch self {
        case .iOS, .tvOS: return ["UIViewController"]
        case .OSX: return ["NSViewController", "NSWindowController"]
        }
    }

    var defaultSegueDestinationType: String {
        switch self {
        case .iOS, .tvOS: return "UIViewController"
        case .OSX: return "NSViewController"
        }
    }

    var storyboardControllerReturnType: String {
        switch self {
        case .iOS, .tvOS: return "UIViewController"
        case .OSX: return "Any" // NSViewController or NSWindowController
        }
    }

    var viewControllerType: String {
        switch self {
        case .iOS, .tvOS: return "UIViewController"
        case .OSX: return "NSViewController"
        }
    }

    var storyboardControllerSignatureType: String {
        switch self {
        case .iOS, .tvOS: return "ViewController"
        case .OSX: return "Controller" // NSViewController or NSWindowController
        }
    }

    var storyboardInstantiationInfo: [(String /* Signature type */, String /* Return type */)] {
        switch self {
        case .iOS, .tvOS: return [("ViewController", "UIViewController")]
        case .OSX: return [("Controller", "NSWindowController"), ("Controller", "NSViewController")]
        }
    }

    var viewType: String {
        switch self {
        case .iOS, .tvOS: return "UIView"
        case .OSX: return "NSView"
        }
    }

    var colorType: String {
        switch self {
        case .iOS, .tvOS: return "UIColor"
        case .OSX: return "NSColor"
        }
    }

    var colorNameType: String {
        switch self {
        case .iOS, .tvOS: return "String"
        case .OSX: return "NSColor.Name"
        }
    }

    var colorOS: String {
        switch self {
        case .iOS: return "iOS 11.0"
        case .tvOS: return "tvOS 11.0"
        case .OSX: return "OSX 10.13"
        }
    }

    var resuableViews: [String]? {
        switch self {
        case .iOS, .tvOS:
            return ["UICollectionReusableView", "UITableViewCell"]
        case .OSX:
            return ["NSTableCellView", "NSTableHeaderView", "NSTableRowView", "NSCollectionViewItem", "NSCollectionViewSectionHeaderView"]
        }
    }

    var resuableItems: [String]? {
        switch self {
        case .iOS, .tvOS:
            return ["collectionReusableView", "tableViewCell"]
        case .OSX:
            return ["tableCellView", "tableHeaderView", "tableRowView", "collectionViewItem", "collectionViewSectionHeaderView"]
        }
    }

    var reusableItemsMap: [String: String] {
        switch self {
        case .iOS, .tvOS:
            return ["collectionReusableView": "UICollectionReusableView", "collectionViewCell": "UICollectionViewCell", "tableViewCell": "UITableViewCell"]
        case .OSX:
            return ["tableCellView": "NSTableCellView", "tableHeaderView": "NSTableHeaderView", "tableRowView": "NSTableRowView", "collectionViewItem": "NSCollectionViewItem", "collectionViewSectionHeaderView": "NSCollectionViewSectionHeaderView"]
		}
	}

    func controllerType(for name: String) -> String? {
        switch self {
        case .iOS, .tvOS:
			switch name {
			case "viewController": return "UIViewController"
			case "navigationController": return "UINavigationController"
			case "tableViewController": return "UITableViewController"
			case "tabBarController":return "UITabBarController"
			case "splitViewController": return "UISplitViewController"
			case "pageViewController": return "UIPageViewController"
			case "collectionViewController": return "UICollectionViewController"
			case "exit": return nil
			case "viewControllerPlaceholder": return "UIViewController"
			default: // assertionFailure("Unknown controller element: \(name)")
                return nil
            }
        case .OSX:
			switch name {
			case "viewController": return "NSViewController"
			case "windowController": return "NSWindowController"
			case "pagecontroller": return "NSPageController"
			case "tabViewController": return "NSTabViewController"
			case "splitViewController": return "NSSplitViewController"
			case "collectionViewItem": return "NSCollectionViewItem"
			case "exit": return nil
			case "viewControllerPlaceholder": return "NSViewController"
			default: // assertionFailure("Unknown controller element: \(name)")
				return nil
            }
        }
    }

}
