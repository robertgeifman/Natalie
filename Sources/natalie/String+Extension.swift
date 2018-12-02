//
//  String+Extension.swift
//  Natalie
//
//  Created by Marcin Krzyzanowski on 07/08/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

extension String {
    func trimAllWhitespacesAndSpecialCharacters() -> String {
        var invalidCharacters = NSMutableCharacterSet.alphanumerics.inverted
        invalidCharacters.remove(charactersIn: "_")
        let x = self.components(separatedBy: invalidCharacters)
        return x.joined(separator: "")
    }
}
