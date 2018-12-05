//
//  Storyboard+Natalie.swift
//  Natalie
//
//  Created by Eric Marchand on 06/06/2017.
//  Copyright © 2017 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

extension Storyboard {
	func processSegues(_ sceneSegues: [Segue]?, _ customClass: String, _ seguesController: inout [String], _ prepareForSegue: inout [String]) -> [String] {
		guard let segues = sceneSegues, !segues.isEmpty else { return [String]() }

		var patterns = [String: Int]()

		for segue in segues {
			guard let srcElement = segue.source.viewController,
				let srcClass = srcElement.customClass ?? os.controllerType(for: srcElement.name),
				let dstID = segue.destination,
				let dstElement = searchById(id: dstID)?.element,
				let dstClass = (dstElement.attribute(by: "customClass")?.text ?? os.controllerType(for: dstElement.name))
			else { continue }

//			let srcID = srcElement.id

			let srcRestorationID = srcElement.xml.element?.attribute(by: "identifier")?.text
			let dstRestorationID = dstElement.attribute(by: "identifier")?.text

			let srcStoryboardID = srcElement.xml.element?.attribute(by: "storyboardIdentifier")?.text
			let dstStoryboardID = dstElement.attribute(by: "storyboardIdentifier")?.text

			let pattern = "(\(segue.identifier.unwrappedString), \(srcRestorationID.unwrappedString), \(srcStoryboardID.unwrappedString), \"\(srcClass)\", \(dstRestorationID.unwrappedString), \(dstStoryboardID.unwrappedString), \"\(dstClass)\")"

			if let value = patterns[pattern] {
				patterns[pattern] = value + 1
			} else {
				patterns[pattern] = 1
			}
		}

		var enumCases = [String]()
		var delegateMethods = [String]()
		var matchPatternsHead = [String]()
		var matchPatterns = [String]()
		var matchCases = [String]()
		var initWithRawValue = [String]()
		var staticVarsValue = [String]()
		var allCases = [String]()

		delegateMethods += "@objc protocol \(customClass)SegueController: NSObjectProtocol {"

		matchPatternsHead += "\t\ttypealias RawValue = (String?, String?, String?, String, String?, String?, String)"
		matchPatternsHead += "\t\tinit?(rawValue: RawValue) {"
		matchPatternsHead += "\t\t\tswitch rawValue {"

		matchPatterns += "\t\t\tdefault: return nil"
		matchPatterns += "\t\t\t}"
		matchPatterns += "\t\t}"
		matchPatterns += ""
		matchPatterns += "\t\tvar rawValue: RawValue {"
		matchPatterns += "\t\t\tswitch self {"

		matchCases += "\toverride func prepare(for segue: NSStoryboardSegue, sender: Any?) {"
		matchCases += "\t\tguard let controller = segueController as? \(customClass)SegueController else { super.prepare(for: segue, sender: sender); return }"
		matchCases += "\t\tswitch segue.matchPattern {"

		for segue in segues {
			guard let srcElement = segue.source.viewController,
				let srcClass = srcElement.customClass ?? os.controllerType(for: srcElement.name),
				let dstID = segue.destination,
				let dstElement = searchById(id: dstID)?.element,
				let dstClass = (dstElement.attribute(by: "customClass")?.text ?? os.controllerType(for: dstElement.name))
			else { continue }

			let srcID = srcElement.id

			let srcRestorationID = srcElement.xml.element?.attribute(by: "identifier")?.text
			let dstRestorationID = dstElement.attribute(by: "identifier")?.text

			let srcStoryboardID = srcElement.xml.element?.attribute(by: "storyboardIdentifier")?.text
			let dstStoryboardID = dstElement.attribute(by: "storyboardIdentifier")?.text

			let pattern = "(\(segue.identifier.unwrappedString), \(srcRestorationID.unwrappedString), \(srcStoryboardID.unwrappedString), \"\(srcClass)\", \(dstRestorationID.unwrappedString), \(dstStoryboardID.unwrappedString), \"\(dstClass)\")"
			let casePattern = "(\(segue.identifier.unwrappedString), \(srcRestorationID.unwrappedPattern), \(srcStoryboardID.unwrappedPattern), \"\(srcClass)\", \(dstRestorationID.unwrappedPattern), \(dstStoryboardID.unwrappedPattern), \"\(dstClass)\")"

			if let value = patterns[pattern], value > 1 {
				continue
			}

			if let segueID = segue.identifier {
				let swiftIdentifier = swiftRepresentation(for: segueID, firstLetter: .lowercase)
				let functionName = "prepareForSegue" + swiftRepresentation(for: segueID, firstLetter: .capitalize)
				let method = "func \(functionName)(_ destination: \(dstClass)?, sender: Any?)"

				allCases += "\t\t\t" + swiftIdentifier + ","

				matchPatterns += "\t\t\tcase .\(swiftIdentifier): return \(pattern)"

				delegateMethods += "\t@objc optional"
				delegateMethods += "\t" + method

				enumCases += "\t\tcase \(swiftIdentifier)"

				matchCases += "\t\tcase \(casePattern):"
				matchCases += "\t\t\tcontroller.\(functionName)?(segue.destinationController as? \(dstClass), sender: sender)"

				initWithRawValue += "\t\t\tcase \(casePattern): self = .\(swiftIdentifier)"

				staticVarsValue += "\t\tstatic var \(swiftIdentifier)Segue = Segue<\(dstClass)>(\"\(segueID)\", kind: .\(segue.kind))"
			} else if segue.kind == "embed" {
				var dstName: String

				if let identifier = dstStoryboardID {
					dstName = swiftRepresentation(for: identifier, firstLetter: .capitalize)
				} else if let identifier = dstRestorationID {
					let customClass = dstElement.attribute(by: "customClass")?.text ?? dstElement.name
					dstName = swiftRepresentation(for: customClass, firstLetter: .capitalize) +
						swiftRepresentation(for: identifier, firstLetter: .capitalize)
				} else if let customClass = dstElement.attribute(by: "customClass")?.text {
					dstName = swiftRepresentation(for: customClass, firstLetter: .capitalize)
				} else {
					dstName = swiftRepresentation(for: dstElement.name, firstLetter: .capitalize) // +
						// swiftRepresentation(for: dstID, firstLetter: .capitalize)
				}

				let swiftIdentifier = "embed" + dstName
				let functionName = "prepareToEmbed" + dstName
				let method = "func \(functionName)(_ destination: \(dstClass)?, sender: Any?)"

				allCases += "\t\t\t" + swiftIdentifier + ","

				matchPatterns += "\t\t\tcase .\(swiftIdentifier): return \(pattern)"

				delegateMethods += "\t@objc optional"
				delegateMethods += "\t" + method

				enumCases += "\t\tcase \(swiftIdentifier)"

				matchCases += "\t\tcase \(casePattern):"
				matchCases += "\t\t\tcontroller.\(functionName)?(segue.destinationController as? \(dstClass), sender: sender)"

				initWithRawValue += "\t\t\tcase \(casePattern): self = .\(swiftIdentifier)"

				staticVarsValue += "\t\tstatic var \(swiftIdentifier)Segue = Segue<\(dstClass)>(kind: .\(segue.kind))"
			} else if segue.kind == "relationship" {
				let relationshipKind = segue.relationshipKind ?? ""

				var dstName = swiftRepresentation(for: relationshipKind, firstLetter: .capitalize) + "To"

				if let identifier = dstElement.attribute(by: "storyboardIdentifier")?.text {
					dstName += swiftRepresentation(for: identifier, firstLetter: .capitalize)
				} else if let identifier = dstRestorationID {
					let customClass = dstElement.attribute(by: "customClass")?.text ?? dstElement.name
					dstName += swiftRepresentation(for: customClass, firstLetter: .capitalize) +
						swiftRepresentation(for: identifier, firstLetter: .capitalize)
				} else if let customClass = dstElement.attribute(by: "customClass")?.text {
					dstName += swiftRepresentation(for: customClass, firstLetter: .capitalize)
				} else {
					dstName += swiftRepresentation(for: dstElement.name, firstLetter: .capitalize) // +
						//swiftRepresentation(for: dstID, firstLetter: .capitalize)
				}

				let swiftIdentifier = "relationship" + dstName
				let functionName = "prepareRelationship" + dstName
				let method = "func \(functionName)(_ destination: \(dstClass)?, sender: Any?)"

				allCases += "\t\t\t" + swiftIdentifier + ","

				matchPatterns += "\t\t\tcase .\(swiftIdentifier): return \(pattern)"

				delegateMethods += "\t@objc optional"
				delegateMethods += "\t" + method

				enumCases += "\t\tcase \(swiftIdentifier)"

				matchCases += "\t\tcase \(casePattern):"
				matchCases += "\t\t\tcontroller.\(functionName)?(segue.destinationController as? \(dstClass), sender: sender)"

				initWithRawValue += "\t\t\tcase \(casePattern): self = .\(swiftIdentifier)"

				staticVarsValue += "\t\tstatic var \(swiftIdentifier)Segue = Segue<\(dstClass)>(kind: .\(segue.kind))"
			}
		}

		if enumCases.isEmpty {
			return [String]()
		}

		if !staticVarsValue.isEmpty {
			staticVarsValue += ""
		}

		staticVarsValue += enumCases
		enumCases = staticVarsValue

		delegateMethods += "}"

		matchPatterns += "\t\t\t}"
		matchPatterns += "\t\t}"
		matchPatterns += ""
//		matchPatterns += "\t\ttypealias AllCases = [Segues]"
		matchPatterns += "\t\tstatic var allCases = [" // : AllCases
		matchPatterns += allCases
		matchPatterns += "\t\t]"

		matchPatternsHead += initWithRawValue
		matchPatternsHead += matchPatterns

		enumCases += ""
		enumCases += matchPatternsHead

		matchCases += "\t\tdefault:"
		matchCases += "\t\t\tsuper.prepare(for: segue, sender: sender)"
		matchCases += "\t\t}"
		matchCases += "\t}"

		seguesController = delegateMethods
		prepareForSegue = matchCases
		return enumCases
	}

	func processViewControllers(storyboardCustomModules: Set<String>) -> [String] {
		var output = [String]()
		for scene in self.scenes {
			guard let viewController = scene.viewController,
				let customClass = viewController.customClass
			else { continue }

			output += "////////////////////////////////////////////////////////////"
			output += "// MARK: - \(customClass)"

			let sceneClass = processIdentifier(scene: scene, storyboardCustomModules: storyboardCustomModules)
			output += sceneClass
			let sceneSegues = scene.segues
			let sceneReusables = viewController.reusables(os)

			var seguesController = [String]()
			var prepareForSegue = [String]()
			let segues = processSegues(sceneSegues, customClass, &seguesController, &prepareForSegue)
			let reusables = processReusables(sceneReusables)

			if !segues.isEmpty || !reusables.isEmpty {
				output += seguesController
				output += ""

				if !segues.isEmpty {
					output += "extension \(customClass): \(customClass)SegueController {"
					output += "\tenum Segues: RawRepresentable, CaseIterable {"
					output += segues
					output += "\t}"
					output += ""
				} else {
					output += "extension \(customClass) {"
				}

				if !reusables.isEmpty {
					output += "\tenum Reusables {"
					output += reusables
					output += "\t}"
				}

				if !segues.isEmpty && !reusables.isEmpty {
					output += ""
				}

				output += prepareForSegue
				output += "}"
			}

			output += ""
		}
		return output
	}

	func processReusables(_ sceneReusables: [Reusable]?) -> [String] {
		var output = [String]()
		if let reusables = sceneReusables, !reusables.isEmpty { // ?.filter({ return $0.reuseIdentifier != nil })
			for reusable in reusables {
				if let identifier = reusable.reuseIdentifier {
					if let customClass = reusable.customClass {
						output += "\t\tstatic var \(swiftRepresentation(for: identifier, doNotShadow: reusable.customClass)): Reusable { return .init(\"\(identifier)\", \"\(reusable.kind)\", \(customClass).self) }"
					} else {
						let customClass = os.reusableItemsMap[reusable.kind]
						output += "\t\tstatic var \(swiftRepresentation(for: identifier)): Reusable { return .init(\"\(identifier)\", \"\(reusable.kind)\", \(customClass!).self) }"
					}
				}
			}
		}
		return output
	}

	struct Format {
		static let pattern = "(\"%s\", %s, \"%s\", %s, \"%s\")"
		static let matchPattern = "\t\t\tcase .%s: return %s"

		static let functionName = "prepareForSegue%s"
		static let method = "func %s(_ destination: %s?, sender: Any?)"

		static let enumCase = "\t\tcase %s"
		static let matchCase = "\t\tcase (\"%s\", %s, \"%s\", %s, \"%s\"): controller.%s?(segue.destinationController as? %s, sender: sender)"
		static let initWithRawValue = "\t\t\tcase (%s, %s, \"%s\", %s, \"%s\"): self = .%s"
		static let staticVarsValue = "\t\tstatic var %sSegue = Segue<%s>(\"%s\", .%s)"
	}
}

extension Optional where Wrapped == String {
	var unwrappedString: String {
		switch self {
		case .none: return "nil"
		case .some(let value): return "\"\(value)\""
		}
	}

	var unwrappedPattern: String {
		switch self {
		case .none: return "_"
		case .some(let value): return "\"\(value)\""
		}
	}
}
