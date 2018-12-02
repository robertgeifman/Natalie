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
    let id: String
    lazy var destination: String? = self.xml.element?.attribute(by: "destination")?.text

    override init(xml: XMLIndexer) {
        self.kind = xml.element!.attribute(by: "kind")!.text
        self.identifier = xml.element?.attribute(by: "identifier")?.text
        self.id = (xml.element?.attribute(by: "id"))!.text
        super.init(xml: xml)
    }

}
