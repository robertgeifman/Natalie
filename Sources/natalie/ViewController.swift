//
//  ViewController.swift
//  Natalie
//
//  Created by Marcin Krzyzanowski on 07/08/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//

class ViewController: XMLObject {

    lazy var customClass: String? = self.xml.element?.attribute(by: "customClass")?.text
    lazy var customModuleProvider: String? = self.xml.element?.attribute(by: "customModuleProvider")?.text
    lazy var storyboardIdentifier: String? = self.xml.element?.attribute(by: "storyboardIdentifier")?.text
    lazy var customModule: String? = self.xml.element?.attribute(by: "customModule")?.text
    lazy var id: String? = self.xml.element?.attribute(by: "id")?.text
    lazy var userLabel: String? = self.xml.element?.attribute(by: "userLabel")?.text

    func reusables(_ os: OS) -> [Reusable]? {
		var objects = [XMLIndexer]()
        if let reusables = self.searchAll(root: self.xml, attributeKey: "reuseIdentifier") {
        	objects.append(contentsOf: reusables)
        }

		if let resuableItems = os.resuableItems {
			for name in resuableItems where self.name == name {
				objects.append(self.xml)
			}
		}
		let result = objects.map { Reusable(xml: $0) }
		return result
    }

    lazy var customClassWithModule: String? = {
        if let className = self.customClass {
            if let moduleName = self.customModule, customModuleProvider != "target" {
                return "\(moduleName).\(className)"
            } else {
                return className
            }
        }
        return nil
    }()

}
