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
			guard let sourceElement = segue.source.viewController,
				let sourceClass = sourceElement.customClass ?? os.controllerType(for: sourceElement.name),
				let destination = segue.destination,
				let destinationElement = searchById(id: destination)?.element,
				let destinationClass = (destinationElement.attribute(by: "customClass")?.text ?? os.controllerType(for: destinationElement.name))
			else { continue }

			let sourceRestorationID = sourceElement.xml.element?.attribute(by: "identifier")?.text
			let destinationRestorationID = destinationElement.attribute(by: "identifier")?.text

			let sourceId = sourceRestorationID == nil ? "nil" : "\"\(sourceRestorationID!)\""
			let destinationId = destinationRestorationID == nil ? "nil" : "\"\(destinationRestorationID!)\""

			var pattern: String?
			if let identifier = segue.identifier {
				pattern = "(\"\(identifier)\", \(sourceId), \"\(sourceClass)\", \(destinationId), \"\(destinationClass)\")"
			} else if segue.kind == "embed" {
				pattern = "(nil, \(sourceId), \"\(sourceClass)\", \(destinationId), \"\(destinationClass)\")"
			} else if segue.kind == "relationship" {
				pattern = "(nil, \(sourceId), \"\(sourceClass)\", \(destinationId), \"\(destinationClass)\")"
			}

			if let pattern = pattern {
				if let value = patterns[pattern] {
					patterns[pattern] = value + 1
				} else {
					patterns[pattern] = 1
				}
			}
		}

		var enumCases = [String]()
		var delegateMethods = [String]()
		var matchPatternsHead = [String]()
		var matchPatterns = [String]()
		var matchCases = [String]()
		var initWithRawValue = [String]()
		var staticVarsValue = [String]()

		delegateMethods += "@objc protocol \(customClass)SegueController: NSObjectProtocol {"

		matchPatternsHead += "\t\ttypealias RawValue = (String?, String?, String, String?, String)"
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
			guard let sourceElement = segue.source.viewController,
				let sourceClass = sourceElement.customClass ?? os.controllerType(for: sourceElement.name),
//				let source = sourceElement.storyboardIdentifier ?? sourceElement.id,
				let destination = segue.destination,
				let destinationElement = searchById(id: destination)?.element,
				let destinationClass = (destinationElement.attribute(by: "customClass")?.text ?? os.controllerType(for: destinationElement.name))
			else { continue }

			let sourceRestorationID = sourceElement.xml.element?.attribute(by: "identifier")?.text
			let destinationRestorationID = destinationElement.attribute(by: "identifier")?.text

			let sourceId = sourceRestorationID == nil ? "nil" : "\"\(sourceRestorationID!)\""
			let destinationId = destinationRestorationID == nil ? "nil" : "\"\(destinationRestorationID!)\""

			let sourceIdCase = sourceRestorationID == nil ? "_" : "\"\(sourceRestorationID!)\""
			let destinationIdCase = destinationRestorationID == nil ? "_" : "\"\(destinationRestorationID!)\""

			if let identifier = segue.identifier {
				let swiftIdentifier = swiftRepresentation(for: identifier, firstLetter: .lowercase)
				let pattern = "(\"\(identifier)\", \(sourceId), \"\(sourceClass)\", \(destinationId), \"\(destinationClass)\")"
				if let value = patterns[pattern], value > 1 {
					continue
				}

				matchPatterns += "\t\t\tcase .\(swiftIdentifier): return \(pattern)"

				let functionName = "prepareForSegue" + swiftRepresentation(for: identifier, firstLetter: .capitalize)
				let method = "func \(functionName)(_ destination: \(destinationClass)?, sender: Any?)"
				delegateMethods += "\t@objc optional"
				delegateMethods += "\t" + method

				enumCases += "\t\tcase \(swiftIdentifier)"
				matchCases += "\t\tcase (\"\(identifier)\", \(sourceIdCase), \"\(sourceClass)\", \(destinationIdCase), \"\(destinationClass)\"):"
				matchCases += "\t\t\tcontroller.\(functionName)?(segue.destinationController as? \(destinationClass), sender: sender)"
				initWithRawValue += "\t\t\tcase (_, \(sourceIdCase), \"\(sourceClass)\", \(destinationIdCase), \"\(destinationClass)\"): self = .\(swiftIdentifier)"
				staticVarsValue += "\t\tstatic var \(swiftIdentifier)Segue = Segue<\(destinationClass)>(\"\(identifier)\", .\(segue.kind))"
			} else if segue.kind == "embed" {
//				let sourceName = swiftRepresentation(for: source, firstLetter: .capitalize)
				var destinationName: String
				if let identifier = destinationElement.attribute(by: "storyboardIdentifier")?.text {
					destinationName = swiftRepresentation(for: identifier, firstLetter: .capitalize)
				} else if let identifier = destinationRestorationID {
					let customClass = destinationElement.attribute(by: "customClass")?.text ?? destinationElement.name
					destinationName = swiftRepresentation(for: customClass, firstLetter: .capitalize) +
						swiftRepresentation(for: identifier, firstLetter: .capitalize)
				} else if let customClass = destinationElement.attribute(by: "customClass")?.text {
					destinationName = swiftRepresentation(for: customClass, firstLetter: .capitalize)
				} else {
					destinationName = swiftRepresentation(for: destinationElement.name, firstLetter: .capitalize) +
						swiftRepresentation(for: destination, firstLetter: .capitalize)
				}

				let swiftIdentifier = segue.kind + destinationName

				let pattern = "(nil, \(sourceId), \"\(sourceClass)\", \(destinationId), \"\(destinationClass)\")"
				if let value = patterns[pattern], value > 1 {
					continue
				}

				matchPatterns += "\t\t\tcase .\(swiftIdentifier): return \(pattern)"

				let functionName = "prepareTo" + swiftRepresentation(for: segue.kind, firstLetter: .capitalize) + destinationName
				let method = "func \(functionName)(_ destination: \(destinationClass)?, sender: Any?)"
				delegateMethods += "\t@objc optional"
				delegateMethods += "\t" + method

				enumCases += "\t\tcase \(swiftIdentifier)"
				matchCases += "\t\tcase (_, \(sourceIdCase), \"\(sourceClass)\", \(destinationIdCase), \"\(destinationClass)\"):"
				matchCases += "\t\t\tcontroller.\(functionName)?(segue.destinationController as? \(destinationClass), sender: sender)"
				initWithRawValue += "\t\t\tcase (_, \(sourceIdCase), \"\(sourceClass)\", \(destinationIdCase), \"\(destinationClass)\"): self = .\(swiftIdentifier)"
//				staticVarsValue += "\t\tstatic var \(swiftIdentifier)Segue = Segue<\(destinationClass)>(\"\(segue.id)\", .\(segue.kind))"
			} else if segue.kind == "relationship" {
				let relationshipKind = segue.relationshipKind ?? ""

//				let sourceName = swiftRepresentation(for: source, firstLetter: .capitalize)
				var destinationName = swiftRepresentation(for: relationshipKind, firstLetter: .capitalize) + "To"

				if let identifier = destinationElement.attribute(by: "storyboardIdentifier")?.text {
					destinationName += swiftRepresentation(for: identifier, firstLetter: .capitalize)
				} else if let identifier = destinationRestorationID {
					let customClass = destinationElement.attribute(by: "customClass")?.text ?? destinationElement.name
					destinationName += swiftRepresentation(for: customClass, firstLetter: .capitalize) +
						swiftRepresentation(for: identifier, firstLetter: .capitalize)
				} else if let customClass = destinationElement.attribute(by: "customClass")?.text {
					destinationName += swiftRepresentation(for: customClass, firstLetter: .capitalize)
				} else {
					destinationName += swiftRepresentation(for: destinationElement.name, firstLetter: .capitalize) +
						swiftRepresentation(for: destination, firstLetter: .capitalize)
				}

				let swiftIdentifier = swiftRepresentation(for: segue.kind, firstLetter: .lowercase) + destinationName

				let pattern = "(nil, \(sourceId), \"\(sourceClass)\", \(destinationId), \"\(destinationClass)\")"
				if let value = patterns[pattern], value > 1 {
					continue
				}

				matchPatterns += "\t\t\tcase .\(swiftIdentifier): return \(pattern)"

				let functionName = "prepare" + swiftRepresentation(for: segue.kind, firstLetter: .capitalize) + destinationName
				let method = "func \(functionName)(_ destination: \(destinationClass)?, sender: Any?)"
				delegateMethods += "\t@objc optional"
				delegateMethods += "\t" + method

				enumCases += "\t\tcase \(swiftIdentifier)"
				matchCases += "\t\tcase (_, \(sourceIdCase), \"\(sourceClass)\", \(destinationIdCase), \"\(destinationClass)\"):"
				matchCases += "\t\t\tcontroller.\(functionName)?(segue.destinationController as? \(destinationClass), sender: sender)"
				initWithRawValue += "\t\t\tcase (_, \(sourceIdCase), \"\(sourceClass)\", \(destinationIdCase), \"\(destinationClass)\"): self = .\(swiftIdentifier)"
//				staticVarsValue += "\t\tstatic var \(swiftIdentifier)Segue = Segue<\(destinationClass)>(\"\(segue.id)\", .\(segue.kind))"
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
}

extension Storyboard {
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
					output += "\tenum Segues: RawRepresentable {"
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
}
