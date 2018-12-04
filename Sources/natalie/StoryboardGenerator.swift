//
//  Natalie.swift
//  Natalie
//
//  Created by Marcin Krzyzanowski on 07/08/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

@discardableResult
func += (_ array: inout [String], _ value: String) -> [String] {
	array.append(value)
	return array
}

@discardableResult
func += (_ array: inout [String], _ value: [String]) -> [String] {
	array.append(contentsOf: value)
	return array
}

struct Natalie {
	struct Header: CustomStringConvertible {
		var description: String {
			var output = String()
			output += "//\n"
			output += "// Autogenerated by Natalie - Storyboard Generator\n"
			output += "// by Marcin Krzyzanowski http://krzyzanowskim.com\n"
			output += "//\n"
			return output
		}
	}

	let storyboards: [StoryboardFile]
	let header = Header()

	var storyboardCustomModules: Set<String> {
		return Set(storyboards.lazy.flatMap { $0.storyboard.customModules })
	}

	init(storyboards: [StoryboardFile]) {
		self.storyboards = storyboards
		assert(Set(storyboards.map { $0.storyboard.os }).count < 2)
	}

	static func process(storyboards: [StoryboardFile]) -> [String] {
		var output = [String]()
		for os in OS.allValues {
			let storyboardsForOS = storyboards.filter { $0.storyboard.os == os }
			if !storyboardsForOS.isEmpty {

				if storyboardsForOS.count != storyboards.count {
					output += "#if os(\(os.rawValue))"
				}

				output += Natalie(storyboards: storyboardsForOS).process(os: os)

				if storyboardsForOS.count != storyboards.count {
					output += "#endif"
				}
			}
		}
		return output
	}

	func process(os: OS) -> [String] {
		var output = [String]()

		output += header.description
		output += "import \(os.framework)"
		for module in storyboardCustomModules {
			output += "import \(module)"
		}
		output += ""

		let storyboardModules = storyboardCustomModules
		for file in storyboards {
			output += file.storyboard.processViewControllers(storyboardCustomModules: storyboardModules)
		}

		output += "////////////////////////////////////////////////////////////"
		output += "enum Storyboards {"
		for file in storyboards {
			output += file.storyboard.processStoryboard(storyboardName: file.storyboardName, os: os)
		}
		output += "}"
		output += ""

		let colors = storyboards
			.flatMap { $0.storyboard.colors }
			.filter { $0.catalog != .system }
			.compactMap { $0.assetName }

		if !colors.isEmpty {
			output += "////////////////////////////////////////////////////////////"
			output += "// MARK: - Colors"
			output += "@available(\(os.colorOS), *)"
			output += "extension \(os.colorType) {"
			for colorName in Set(colors) {
				output += "\tstatic let \(swiftRepresentation(for: colorName, firstLetter: .none)) = \(os.colorType)(named: \(initIdentifier(for: os.colorNameType, value: colorName)))"
			}
			output += "}"
			output += ""
		}

		return output
	}
}
