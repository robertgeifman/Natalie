//
//  String+Extension.swift
//  Natalie
//
//  Created by Marcin Krzyzanowski on 07/08/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

extension String {
    fileprivate static var invalidCharacters: CharacterSet = {
			var charset = CharacterSet.alphanumerics.inverted
			charset.remove(charactersIn: "_")
			return charset
		}()
    func trimAllWhitespacesAndSpecialCharacters() -> String {
        let x = self.components(separatedBy: String.invalidCharacters)
        return x.joined(separator: "")
    }

    func trimCapitalizingAllWhitespacesAndSpecialCharacters() -> String {
        let x = self.components(separatedBy: String.invalidCharacters)
        return x.map {
        	$0.isEmpty ? $0 : String($0.uppercased().unicodeScalars.prefix(1) + $0.unicodeScalars.suffix($0.unicodeScalars.count - 1))
        }.joined(separator: "")
    }
}

extension Optional where Wrapped == String {
	var unwrappedString: String {
		switch self {
		case .none: return "nil"
		case .some(let value): return value.isEmpty ? "nil" : "\"\(value)\""
		}
	}

	var unwrappedPattern: String {
		switch self {
		case .none: return "_"
		case .some(let value): return value.isEmpty ? "\"\"" : "\"\(value)\""
		}
	}
}
