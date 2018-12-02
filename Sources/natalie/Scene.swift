//
//  Scene.swift
//  Natalie
//
//  Created by Marcin Krzyzanowski on 07/08/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//

class Scene: XMLObject {

    lazy var viewController: ViewController? = {
        if let vcs = self.searchAll(attributeKey: "sceneMemberID", attributeValue: "viewController"), let vc = vcs.first {
            return ViewController(xml: vc)
        }
        return nil
    }()

    lazy var segues: [Segue]? = {
        let segues = self.searchNamed(name: "segue")
        return segues?.map { Segue(xml: $0) }
    }()

    lazy var sceneID: String? = self.xml.element?.attribute(by: "sceneID")?.text

    lazy var customModule: String? = self.viewController?.customModule
    lazy var customModuleProvider: String? = self.viewController?.customModuleProvider
    lazy var userLabel: String? = self.viewController?.userLabel

}
