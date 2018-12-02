//
//  Segue.swift
//  Natalie
//
//  Created by Marcin Krzyzanowski on 07/08/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//

import Cocoa

class Segue: XMLObject {

    let kind: String
    let identifier: String?
    lazy var destination: String? = self.xml.element?.attribute(by: "destination")?.text

    override init(xml: XMLIndexer) {
        self.kind = xml.element!.attribute(by: "kind")!.text
        var id = xml.element?.attribute(by: "identifier")?.text
        if nil == id || id!.isEmpty {
			if let value = xml.element?.attribute(by: "id")?.text {
				id = "segue_" + value
			}
        }
		self.identifier = id
        super.init(xml: xml)
    }

}
