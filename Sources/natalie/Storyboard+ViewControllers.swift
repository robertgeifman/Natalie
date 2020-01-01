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
			else {
				continue
			}

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
		var matchPatterns = [String]()
		var seguePatterns = [String]()
		var canMatchCases = [String]()
		var matchCases = [String]()

		var canUnwindCases = [String]()
		var unwindMethods = [String]()
		var initWithRawValue = [String]()
		var staticVarsValue = [String]()
		var allCases = [String]()

		delegateMethods += "@objc protocol \(customClass)Coordinator: NSObjectProtocol {"

		matchPatterns += "\t\tvar matchPattern: (String?, String?, String?, \(os.viewControllerType).Type, String?, String?, \(os.viewControllerType).Type) {"
		matchPatterns += "\t\t\tswitch self {"

		seguePatterns += "\t\tvar segue: AnySegue {"
		seguePatterns += "\t\t\tswitch self {"

		matchCases += "\toverride func prepare(for segue: \(os.storyboardSegueType), sender: Any?) {"
		matchCases += "\t\tguard let coordinator = _coordinator as? \(customClass)Coordinator else {"
		matchCases += "\t\t\treturn super.prepare(for: segue, sender: sender)"
		matchCases += "\t\t}"
		matchCases += "\t\tswitch segue.matchPattern {"

		canMatchCases += "\toverride func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {"
		canMatchCases += "\t\tguard let coordinator = _coordinator as? \(customClass)Coordinator else {"
		canMatchCases += "\t\t\treturn super.shouldPerformSegue(withIdentifier: identifier, sender: sender)"
		canMatchCases += "\t\t}"
		canMatchCases += "\t\tswitch identifier {"

		canUnwindCases += "\toverride func canPerformUnwindSegueAction(_ action: Selector, from: UIViewController, withSender sender: Any) -> Bool {"
		canUnwindCases += "\t\tguard let coordinator = _coordinator as? \(customClass)Coordinator else {"
		canUnwindCases += "\t\t\treturn super.canPerformUnwindSegueAction(action, from: from, withSender: sender)"
		canUnwindCases += "\t\t}"
		canUnwindCases += "\t\tswitch (action, from) {"

		var hasIdentifiableSegues = false
		for segue in segues {
			guard let srcElement = segue.source.viewController,
				let srcClass = srcElement.customClass ?? os.controllerType(for: srcElement.name),
				let dstID = segue.destination,
				let dstElement = searchById(id: dstID)?.element,
				let dstClass = (dstElement.attribute(by: "customClass")?.text ?? os.controllerType(for: dstElement.name))
			else { continue }

			let srcRestorationID = srcElement.xml.element?.attribute(by: "identifier")?.text
			let dstRestorationID = dstElement.attribute(by: "identifier")?.text

			let srcStoryboardID = srcElement.xml.element?.attribute(by: "storyboardIdentifier")?.text
			let dstStoryboardID = dstElement.attribute(by: "storyboardIdentifier")?.text

			let pattern =
				"(\(segue.identifier.unwrappedString), \(srcRestorationID.unwrappedString), \(srcStoryboardID.unwrappedString), \(srcClass).self, \(dstRestorationID.unwrappedString), \(dstStoryboardID.unwrappedString), \(dstClass).self)"
			
			let srcCast = (srcClass == "UIViewController"||srcClass == "NSViewController") ? "_" : "is \(srcClass).Type"
			let dstCast = (dstClass == "UIViewController"||dstClass == "NSViewController") ? "_" : "is \(dstClass).Type"
			let casePattern =
				"(\(segue.identifier.unwrappedString), \(srcRestorationID.unwrappedPattern), \(srcStoryboardID.unwrappedPattern), \(srcCast), \(dstRestorationID.unwrappedPattern), \(dstStoryboardID.unwrappedPattern), \(dstCast))"

			if let value = patterns[pattern], value > 1 {
				continue
			}

			if let segueID = segue.identifier, !segueID.isEmpty, segue.kind != "embed", segue.kind != "relationship" {
				hasIdentifiableSegues = true // hasIdentifiableSegues || (segue.kind != "embed" && segue.kind != "relationship")
				let swiftIdentifier = swiftRepresentation(for: segueID, firstLetter: .lowercase)

				let canPerformFunctionName = "canPerformSegue" + swiftRepresentation(for: segueID, firstLetter: .capitalize)
				let canPerformMethod = "func \(canPerformFunctionName)(sender: Any?) -> Bool"

				let functionName = "prepareForSegue" + swiftRepresentation(for: segueID, firstLetter: .capitalize)
				let method = "func \(functionName)(_ destination: \(dstClass)?, sender: Any?)"

				let canUnwindFunctionName = "canUnwind" + swiftRepresentation(for: segueID, firstLetter: .capitalize)
				let canUnwindMethod = "func \(canUnwindFunctionName)(from: \(dstClass), sender: Any?) -> Bool"

				let unwindFunctionName = "unwind" + swiftRepresentation(for: segueID, firstLetter: .capitalize)
				let unwindMethod = "func \(unwindFunctionName)(from: \(dstClass), to: \(srcClass))"
			
				allCases += "\t\t\t" + swiftIdentifier + ","

				matchPatterns += "\t\t\tcase .\(swiftIdentifier): return \(pattern)"

				delegateMethods += "\t@objc optional"
				delegateMethods += "\t" + method

				delegateMethods += "\t@objc optional"
				delegateMethods += "\t" + canPerformMethod
				delegateMethods += "\t@objc optional"
				delegateMethods += "\t" + canUnwindMethod
				delegateMethods += "\t@objc optional"
				delegateMethods += "\t" + unwindMethod

				unwindMethods += "\t@IBAction func \(unwindFunctionName)(segue: UIStoryboardSegue) {"
				unwindMethods += "\t\tguard let coordinator = _coordinator as? \(customClass)Coordinator,"
				unwindMethods += "\t\t\tlet source = segue.source as? \(dstClass),"
				unwindMethods += "\t\t\tlet destination = segue.destination as? \(srcClass)"
				unwindMethods += "\t\telse { return }"
				unwindMethods += "\t\tcoordinator.\(unwindFunctionName)?(from: source, to: destination)"
				unwindMethods += "\t}"

				enumCases += "\t\tcase \(swiftIdentifier) = \"\(segueID)\""

				canMatchCases += "\t\tcase Segues.\(swiftIdentifier).rawValue:"
				canMatchCases += "\t\t\treturn coordinator.\(canPerformFunctionName)?(sender: sender) ?? true"

				matchCases += "\t\tcase \(casePattern):"
				canUnwindCases += "\t\tcase (#selector(\(unwindFunctionName)(segue:)), \(dstCast)):"
				if dstCast == "_" {
					matchCases += "\t\t\tcoordinator.\(functionName)?(segue.destinationController, sender: sender)"
					canUnwindCases += "\t\t\treturn coordinator.\(canUnwindFunctionName)?(from: from, sender: sender) ??"
				} else {
					matchCases += "\t\t\tcoordinator.\(functionName)?(segue.destinationController as? \(dstClass), sender: sender)"
					canUnwindCases += "\t\t\treturn coordinator.\(canUnwindFunctionName)?(from: from as! \(dstClass), sender: sender) ??"
				}

				canUnwindCases += "\t\t\t\tsuper.canPerformUnwindSegueAction(action, from: from, withSender: sender)"

				initWithRawValue += "\t\t\tcase \(casePattern): self = .\(swiftIdentifier)"

				seguePatterns += "\t\t\tcase .\(swiftIdentifier):  return Segue<\(dstClass)>(\"\(segueID)\", kind: .\(segue.kind))"
			} else if segue.kind == "embed" {
				var dstName: String
				if let segueID = segue.identifier, !segueID.isEmpty {
					dstName = swiftRepresentation(for: segueID, firstLetter: .capitalize)
				} else if let identifier = dstStoryboardID {
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
				// let canEmbedFunctionName = "canEmbed" + dstName
				// let canEmbedMethod = "func \(canEmbedFunctionName)(_ destination: \(dstClass)?, sender: Any?)"

				allCases += "\t\t\t" + swiftIdentifier + ","

				matchPatterns += "\t\t\tcase .\(swiftIdentifier): return \(pattern)"

				// delegateMethods += "\t@objc optional"
				// delegateMethods += "\t" + canEmbedMethod
				delegateMethods += "\t@objc optional"
				delegateMethods += "\t" + method

				enumCases += "\t\tcase \(swiftIdentifier) = \"\(dstID)\""

				matchCases += "\t\tcase \(casePattern):"
				matchCases += "\t\t\tcoordinator.\(functionName)?(segue.destinationController as? \(dstClass), sender: sender)"

				initWithRawValue += "\t\t\tcase \(casePattern): self = .\(swiftIdentifier)"

				seguePatterns += "\t\t\tcase .\(swiftIdentifier):  return Segue<\(dstClass)>(kind: .\(segue.kind))"
			} else if segue.kind == "relationship" {
				let relationshipKind = segue.relationshipKind ?? ""

				var dstName = swiftRepresentation(for: relationshipKind, firstLetter: .capitalize) + "To"

				if let segueID = segue.identifier, !segueID.isEmpty {
					dstName = swiftRepresentation(for: segueID, firstLetter: .capitalize)
				} else if let identifier = dstElement.attribute(by: "storyboardIdentifier")?.text {
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
				// let canEstablishFunctionName = "canEstablishRelationship" + dstName
				// let canEstablishMethod = "func \(canEstablishFunctionName)(_ destination: \(dstClass)?, sender: Any?)"

				allCases += "\t\t\t" + swiftIdentifier + ","

				matchPatterns += "\t\t\tcase .\(swiftIdentifier): return \(pattern)"

				// delegateMethods += "\t@objc optional"
				// delegateMethods += "\t" + canEstablishMethod
				delegateMethods += "\t@objc optional"
				delegateMethods += "\t" + method

				enumCases += "\t\tcase \(swiftIdentifier) = \"\(dstID)\""

				matchCases += "\t\tcase \(casePattern):"
				matchCases += "\t\t\tcoordinator.\(functionName)?(segue.destinationController as? \(dstClass), sender: sender)"

				initWithRawValue += "\t\t\tcase \(casePattern): self = .\(swiftIdentifier)"

				seguePatterns += "\t\t\tcase .\(swiftIdentifier):  return Segue<\(dstClass)>(kind: .\(segue.kind))"
			} else {
				print(segue.kind)
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

		seguePatterns += "\t\t\t}"
		seguePatterns += "\t\t}"
		seguePatterns += ""

		matchPatterns += "\t\t\t}"
		matchPatterns += "\t\t}"
		matchPatterns += ""
		
		matchCases += "\t\tdefault:"
		matchCases += "\t\t\tsuper.prepare(for: segue, sender: sender)"
		matchCases += "\t\t}"
		matchCases += "\t}"
		matchCases += ""

		canMatchCases += "\t\tdefault:"
		canMatchCases += "\t\t\treturn super.shouldPerformSegue(withIdentifier: identifier, sender: sender)"
		canMatchCases += "\t\t}"
		canMatchCases += "\t}"
		canMatchCases += ""

		canUnwindCases += "\t\tdefault:"
		canUnwindCases += "\t\t\treturn super.canPerformUnwindSegueAction(action, from: from, withSender: sender)"
		canUnwindCases += "\t\t}"
		canUnwindCases += "\t}"
		canUnwindCases += ""
		canUnwindCases += "\t@available(iOS 13.0, *)"
		canUnwindCases += "\toverride func canPerformUnwindSegueAction(_ action: Selector, from: UIViewController, sender: Any?) -> Bool {"
		canUnwindCases += "\t\tsuper.canPerformUnwindSegueAction(action, from: from, withSender: sender ?? from)"
		canUnwindCases += "\t}"
		canUnwindCases += ""

		enumCases += ""
		enumCases += "\t\tstatic var allCases = ["
		enumCases += allCases
		enumCases += "\t\t]"
		enumCases += ""
		enumCases += seguePatterns
		enumCases += matchPatterns

		seguesController = delegateMethods
		prepareForSegue = hasIdentifiableSegues ? canMatchCases + canUnwindCases + matchCases + unwindMethods : matchCases
		return enumCases
	}

	func processViewControllers(storyboardCustomModules: Set<String>) -> [String] {
		var output = [String]()
		for scene in self.scenes {
			guard let viewController = scene.viewController,
				let customClass = viewController.customClass
			else { continue }

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
					output += "extension \(customClass): \(customClass)Coordinator {"
					output += "\tenum Segues: String, CaseIterable {"
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
						output += "\t\tstatic var \(swiftRepresentation(for: identifier, doNotShadow: reusable.customClass)): Reusable { .init(\"\(identifier)\", \"\(reusable.kind)\", \(customClass).self) }"
					} else {
						let customClass = os.reusableItemsMap[reusable.kind]
						output += "\t\tstatic var \(swiftRepresentation(for: identifier)): Reusable { .init(\"\(identifier)\", \"\(reusable.kind)\", \(customClass!).self) }"
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
		static let canPerformFunctionName = "canPerformSegue%s"
		static let canPerformMethod = "func %s(sender: Any?) -> Bool"

		static let enumCase = "\t\tcase %s"
		static let matchCase = "\t\tcase (\"%s\", %s, \"%s\", %s, \"%s\"): coordinator.%s?(segue.destinationController as? %s, sender: sender)"
		static let initWithRawValue = "\t\t\tcase (%s, %s, \"%s\", %s, \"%s\"): self = .%s"
		static let staticVarsValue = "\t\tstatic var %sSegue = Segue<%s>(\"%s\", .%s)"
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
		case .some(let value): return value.isEmpty ? "nil" : "\"\(value)\""
		}
	}
}
