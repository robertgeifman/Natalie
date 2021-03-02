//
//  Reusable.swift
//  Natalie
//
//  Created by Marcin Krzyzanowski on 07/08/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//

class Reusable: XMLObject {
    let kind: String
    let key: String
    lazy var customClass: String? = xml.element?.attribute(by: "customClass")?.text
    lazy var reuseIdentifier: String? = {
    	if let value = xml.element?.attribute(by: "reuseIdentifier")?.text { return value }
    	if let value = xml.element?.attribute(by: "storyboardIdentifier")?.text { return value }
    	if let value = xml.element?.attribute(by: "identifier")?.text { return value }
    	let value = (xml.element?.attribute(by: "id"))!.text
    	return kind + "_" + value
	}()

    override init(xml: XMLIndexer) {
        kind = xml.element!.name
        key = xml.element?.attribute(by: "key")?.text ?? "cell"
        super.init(xml: xml)
    }
}
