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
			guard
				// let srcElement = segue.source.viewController,
				// let srcClass = srcElement.customClass ?? os.controllerType(for: srcElement.name),
				let dstID = segue.destination,
				let dstElement = searchById(id: dstID)?.element,
				let dstClass = (dstElement.attribute(by: "customClass")?.text ?? os.controllerType(for: dstElement.name))
			else {
				continue
			}

			// let srcStoryboardID = srcElement.xml.element?.attribute(by: "storyboardIdentifier")?.text
			let dstStoryboardID = dstElement.attribute(by: "storyboardIdentifier")?.text
			let pattern = "(\(segue.identifier.unwrappedString), \(dstStoryboardID.unwrappedString), \(dstClass).self)"

			if let value = patterns[pattern] {
				patterns[pattern] = value + 1
			} else {
				patterns[pattern] = 1
			}
		}

		var numberOfCases = 0
		var enumCases = [String]()
		var delegateMethods = [String]()
		var defaultImplementation = [String]()
		var seguePatterns = [String]()
		var canMatchCases = [String]()
		var matchCases = [String]()

		var canUnwindCases = [String]()
		var unwindMethods = [String]()
		var initWithRawValue = [String]()
		var allCases = [String]()

		delegateMethods += "protocol \(customClass)Scene: AnyScene {"

		defaultImplementation += "extension \(customClass)Scene {"

		matchCases += "\tvar sceneCoordinator: \(customClass)Scene { (_sceneCoordinator as? \(customClass)Scene).require() }"
		matchCases += "\toverride func prepare(for segue: \(os.storyboardSegueType), sender: Any?) {"
		matchCases += "\t\tswitch segue.matchPattern {"

		canMatchCases += "\toverride func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {"
		canMatchCases += "\t\tswitch identifier {"

		canUnwindCases += "\toverride func canPerformUnwindSegueAction(_ action: Selector, from: UIViewController, withSender sender: Any) -> Bool {"
		canUnwindCases += "\t\tswitch (action, from) {"

		var hasIdentifiableSegues = false
		for segue in segues {
			guard let srcElement = segue.source.viewController,
				let srcClass = srcElement.customClass ?? os.controllerType(for: srcElement.name),
				let dstID = segue.destination,
				let dstElement = searchById(id: dstID)?.element,
				let dstClass = (dstElement.attribute(by: "customClass")?.text ?? os.controllerType(for: dstElement.name))
			else { continue }

			// let srcStoryboardID = srcElement.xml.element?.attribute(by: "storyboardIdentifier")?.text
			let dstStoryboardID = dstElement.attribute(by: "storyboardIdentifier")?.text

			let pattern = "(\(segue.identifier.unwrappedString), \(dstStoryboardID.unwrappedString), \(dstClass).self)"

			let srcCast = (srcClass == "UIViewController"||srcClass == "NSViewController") ? "_" : "is \(srcClass).Type"
			let dstCast = (dstClass == "UIViewController"||dstClass == "NSViewController") ? "_" : "is \(dstClass).Type"
			let dstCastUnwind = (dstClass == "UIViewController"||dstClass == "NSViewController") ? "_" : "is \(dstClass)"
			// let srcRef = (srcClass == "UIViewController"||srcClass == "NSViewController") ? "_" : "\(srcStoryboardID.unwrappedPattern)"
			let dstRef = (dstClass == "UIViewController"||dstClass == "NSViewController") ? "_" : "\(dstStoryboardID.unwrappedPattern)"
			if let value = patterns[pattern], value > 1 {
				continue
			}

			if let segueID = segue.identifier, !segueID.isEmpty, segue.kind != "embed", segue.kind != "relationship" {
				hasIdentifiableSegues = true // hasIdentifiableSegues || (segue.kind != "embed" && segue.kind != "relationship")
				let swiftIdentifier = swiftRepresentation(for: segueID, firstLetter: .lowercase)
				let dstName = swiftRepresentation(for: segueID, firstLetter: .capitalize)

				let segueName = dstName.first!.lowercased() + dstName.dropFirst()

				let casePattern = "(Segues.\(segueName).identifier, \(dstRef), \(dstCast))"

				let canPerformFunctionName = "canPerformSegue" + dstName
				let canPerformMethod = "\(canPerformFunctionName)(sender: Any?) -> Bool"

				let functionName = "prepareForSegue" + dstName
				let method = "\(functionName)(_ destination: \(dstClass), sender: Any?)"

				let canUnwindFunctionName = "canUnwind" + dstName
				let canUnwindMethod = "\(canUnwindFunctionName)(from: \(dstClass), sender: Any?) -> Bool"

				let unwindFunctionName = "unwind" + dstName
				let unwindMethod = "\(unwindFunctionName)(from: \(dstClass), to: \(srcClass))"
		
				allCases += "\t\t\t\(segueName),"
				if segue.kind == "custom" {
					if let customSegueClassAttr = segue.xml.element?.attribute(by: "customClass") {
						let customSegueClass = customSegueClassAttr.text
						seguePatterns += "\t\tstatic let \(segueName) = Segue<\(dstClass)>(\"\(segueID)\", kind: .\(segue.kind)(\(customSegueClass).self)) {"
						seguePatterns += "\t\t\tsource, destination, segue, kind in"
						seguePatterns += "\t\t\tsource.\(functionName)(destination, sender: source)"
						seguePatterns += "\t\t}"
					} else {
						seguePatterns += "\t\t#warning(\"no custom class set for segue \(segueName) to \(dstClass) (\(segueID))\")"
					}
				} else {
					seguePatterns += "\t\tstatic let \(segueName) = Segue<\(dstClass)>(\"\(segueID)\", kind: .\(segue.kind)) {"
					seguePatterns += "\t\t\tsource, destination, segue, kind in"
					seguePatterns += "\t\t\tsource.\(functionName)(destination, sender: source)"
					seguePatterns += "\t\t}"
				}

				delegateMethods += "\tfunc " + method
				delegateMethods += "\tfunc " + canPerformMethod
				delegateMethods += "\tfunc " + canUnwindMethod
				delegateMethods += "\tfunc " + unwindMethod

				defaultImplementation += "\tfunc " + method + " {"
				defaultImplementation += "\t\tprint(\"func \(customClass).\(method) {\\n}\")"
				defaultImplementation += "\t}"

				defaultImplementation += "\tfunc " + canPerformMethod + " {"
				defaultImplementation += "\t\tprint(\"func \(customClass).\(canPerformMethod) {\\n}\"); return true"
				defaultImplementation += "\t}"

				defaultImplementation += "\tfunc " + canUnwindMethod + " {"
				defaultImplementation +=  "\t\tprint(\"func \(customClass).\(canUnwindMethod) {\\n}\"); return true"
				defaultImplementation += "\t}"

				defaultImplementation += "\tfunc " + unwindMethod + " {"
				defaultImplementation +=  "\t\tprint(\"func \(customClass).\(unwindMethod) {\\n}\")"
				defaultImplementation += "\t}"

				unwindMethods += "\t@IBAction func \(unwindFunctionName)(segue: UIStoryboardSegue) {"
				
				if dstCast == "_" {
					unwindMethods += "\t\tlet source = segue.source"
				} else {
					unwindMethods += "\t\tguard let source = segue.source as? \(dstClass) else { return }"
				}
				
				if srcCast == "_" {
					unwindMethods += "\t\tlet destination = segue.destination"
				} else {
					unwindMethods += "\t\tguard let destination = segue.destination as? \(srcClass) else { return }"
				}
				
				unwindMethods += ""
				unwindMethods += "\t\tsceneCoordinator.\(unwindFunctionName)(from: source, to: destination)"
				unwindMethods += "\t}"
				unwindMethods += ""

				numberOfCases += 1

				canMatchCases += "\t\tcase Segues.\(segueName).identifier:"
				canMatchCases += "\t\t\treturn sceneCoordinator.\(canPerformFunctionName)(sender: sender)"

//				if dstCast != dstRef {
					matchCases += "\t\tcase \(casePattern):"
					if dstCast == "_" {
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(segue.destinationController, sender: sender)"
					} else {
						matchCases += "\t\t\tlet dst = (segue.destinationController as? \(dstClass)).require()"
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(dst, sender: sender)"
					}
					initWithRawValue += "\t\t\tcase \(casePattern): self = .\(swiftIdentifier)"
//				}
				
				canUnwindCases += "\t\tcase (#selector(\(unwindFunctionName)(segue:)), \(dstCastUnwind)):"
				if dstCast == "_" {
					canUnwindCases += "\t\t\treturn sceneCoordinator.\(canUnwindFunctionName)(from: from, sender: sender)"
				} else {
					canUnwindCases += "\t\t\treturn sceneCoordinator.\(canUnwindFunctionName)(from: from as! \(dstClass), sender: sender)"
				}
			} else if segue.kind == "presentation" {
				var dstName: String
				var segueIdentifier: String?
				if let segueID = segue.identifier, !segueID.isEmpty {
					dstName = swiftRepresentation(for: segueID, firstLetter: .capitalize)
					segueIdentifier = segueID
				} else if let identifier = dstStoryboardID {
					dstName = swiftRepresentation(for: identifier, firstLetter: .capitalize)
				} else if let customClass = dstElement.attribute(by: "customClass")?.text {
					dstName = swiftRepresentation(for: customClass, firstLetter: .capitalize)
				} else {
					dstName = swiftRepresentation(for: dstElement.name, firstLetter: .capitalize) + "_" + swiftRepresentation(for: dstID, firstLetter: .capitalize)
				}
				let segueName = dstName.first!.lowercased() + dstName.dropFirst()

				let casePattern = nil == segueIdentifier ?
					"(_, \(dstRef), \(dstCast))" :
					"(Segues.\(segueName).identifier, \(dstRef), \(dstCast))"
					
				let swiftIdentifier = "present" + dstName
				let functionName = "prepareToPresent" + dstName
				let method = "\(functionName)(_ destination: \(dstClass), sender: Any?)"

				if let segueIdentifier = segueIdentifier {
					allCases += "\t\t\t\(segueName),"
					seguePatterns += "\t\tstatic let \(segueName) = Segue<\(dstClass)>(\"\(segueIdentifier)\", kind: .\(segue.kind)) {"
					seguePatterns += "\t\t\tsource, destination, segue, kind in"
					seguePatterns += "\t\t\tsource.\(functionName)(destination, sender: source)"
					seguePatterns += "\t\t}"
				}

				numberOfCases += 1

				if dstCast != dstRef {
					delegateMethods += "\tfunc " + method
					defaultImplementation += "\tfunc " + method + " {"
					defaultImplementation += "\t\tprint(\"func \(customClass).\(method) {\\n}\")"
					defaultImplementation += "\t}"

					matchCases += "\t\tcase \(casePattern):"
					if dstCast == "_" {
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(segue.destinationController, sender: sender)"
					} else {
						matchCases += "\t\t\tlet dst = (segue.destinationController as? \(dstClass)).require()"
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(dst, sender: sender)"
					}
				}
				
				initWithRawValue += "\t\t\tcase \(casePattern): self = .\(swiftIdentifier)"
			} else if segue.kind == "embed" {
				var dstName: String
				var segueIdentifier: String?
				if let segueID = segue.identifier, !segueID.isEmpty {
					dstName = swiftRepresentation(for: segueID, firstLetter: .capitalize)
					segueIdentifier = segueID
				} else if let identifier = dstStoryboardID {
					dstName = swiftRepresentation(for: identifier, firstLetter: .capitalize)
				} else if let customClass = dstElement.attribute(by: "customClass")?.text {
					dstName = swiftRepresentation(for: customClass, firstLetter: .capitalize)
				} else {
					dstName = swiftRepresentation(for: dstElement.name, firstLetter: .capitalize) + "_" + swiftRepresentation(for: dstID, firstLetter: .capitalize)
				}

				let segueName = dstName.first!.lowercased() + dstName.dropFirst()

				let casePattern = nil == segueIdentifier ?
					"(_, \(dstRef), \(dstCast))" :
					"(Segues.\(segueName).identifier, \(dstRef), \(dstCast))"

				let swiftIdentifier = "embed" + dstName
				let functionName = "prepareToEmbed" + dstName
				let method = "\(functionName)(_ destination: \(dstClass), sender: Any?)"

				if let segueIdentifier = segueIdentifier {
					allCases += "\t\t\t\(segueName),"
					seguePatterns += "\t\tstatic let \(segueName) = Segue<\(dstClass)>(\"\(segueIdentifier)\", kind: .\(segue.kind)) {"
					seguePatterns += "\t\t\tsource, destination, segue, kind in"
					seguePatterns += "\t\t\tsource.\(functionName)(destination, sender: source)"
					seguePatterns += "\t\t}"
				}

				numberOfCases += 1

				if dstCast != dstRef {
					delegateMethods += "\tfunc " + method
					defaultImplementation += "\tfunc " + method + " {"
					defaultImplementation += "\t\tprint(\"func \(customClass).\(method) {\\n}\")"
					defaultImplementation += "\t}"

					matchCases += "\t\tcase \(casePattern):"
					if dstCast == "_" {
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(segue.destinationController, sender: sender)"
					} else {
						matchCases += "\t\t\tlet dst = (segue.destinationController as? \(dstClass)).require()"
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(dst, sender: sender)"
					}
				}
				
				initWithRawValue += "\t\t\tcase \(casePattern): self = .\(swiftIdentifier)"
			} else if segue.kind == "relationship" {
				let relationshipKind = segue.relationshipKind ?? ""

				var dstName = swiftRepresentation(for: relationshipKind, firstLetter: .capitalize) + "To"

				var segueIdentifier: String?
				if let segueID = segue.identifier, !segueID.isEmpty {
					dstName = swiftRepresentation(for: segueID, firstLetter: .capitalize)
					segueIdentifier = segueID
				} else if let identifier = dstElement.attribute(by: "storyboardIdentifier")?.text {
					dstName += swiftRepresentation(for: identifier, firstLetter: .capitalize)
				} else if let customClass = dstElement.attribute(by: "customClass")?.text {
					dstName += swiftRepresentation(for: customClass, firstLetter: .capitalize)
				} else {
					dstName = swiftRepresentation(for: dstElement.name, firstLetter: .capitalize) + "_" + swiftRepresentation(for: dstID, firstLetter: .capitalize)
				}

				let segueName = dstName.first!.lowercased() + dstName.dropFirst()
				let casePattern = nil == segueIdentifier ?
					"(_, \(dstRef), \(dstCast))" :
					"(Segues.\(segueName).identifier, \(dstRef), \(dstCast))"

				let swiftIdentifier = "relationship" + dstName
				let functionName = "prepareRelationship" + dstName
				let method = "\(functionName)(_ destination: \(dstClass), sender: Any?)"

				if let segueIdentifier = segueIdentifier {
					allCases += "\t\t\t\(segueName),"
					seguePatterns += "\t\tstatic let \(segueName) = Segue<\(dstClass)>(\"\(segueIdentifier)\", kind: .\(segue.kind)) {"
					seguePatterns += "\t\t\tsource, destination, segue, kind in"
					seguePatterns += "\t\t\tsource.\(functionName)(destination, sender: source)"
					seguePatterns += "\t\t}"
				}

				numberOfCases += 1
				
				if dstCast != dstRef {
					delegateMethods += "\tfunc " + method
					defaultImplementation += "\tfunc " + method + " {"
					defaultImplementation += "\t\tprint(\"func \(customClass).\(method) {\\n}\")"
					defaultImplementation += "\t}"	

					matchCases += "\t\tcase \(casePattern):"
					if dstCast == "_" {
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(segue.destinationController, sender: sender)"
					} else {
						matchCases += "\t\t\tlet dst = (segue.destinationController as? \(dstClass)).require()"
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(dst, sender: sender)"
					}
				}
				
				initWithRawValue += "\t\t\tcase \(casePattern): self = .\(swiftIdentifier)"
			}
		}

		if numberOfCases == 0 {
			return [String]()
		}

		delegateMethods += "}"
		delegateMethods += ""
		defaultImplementation += "}"
		
		matchCases += "\t\tdefault:"
		matchCases += "\t\t\tsuper.prepare(for: segue, sender: sender)"
		matchCases += "\t\t}"
		matchCases += "\t}"

		canMatchCases += "\t\tdefault:"
		canMatchCases += "\t\t\treturn super.shouldPerformSegue(withIdentifier: identifier, sender: sender)"
		canMatchCases += "\t\t}"
		canMatchCases += "\t}"
		canMatchCases += ""

		canUnwindCases += "\t\tdefault:"
		canUnwindCases += "\t\t\treturn super.canPerformUnwindSegueAction(action, from: from, withSender: sender)"
		canUnwindCases += "\t\t}"
		canUnwindCases += "\t}"
/*
		var performSegue = [String]()
		performSegue += ""
		performSegue += "\tfunc perform(_ segue: Segue) {"
		performSegue += "\t\tperform(segue, prepare: segue.prepare)"
		performSegue += "\t}"
*/
		enumCases += seguePatterns

		seguesController = delegateMethods + defaultImplementation
		if hasIdentifiableSegues {
			matchCases += ""
			prepareForSegue = matchCases + unwindMethods + canMatchCases + canUnwindCases
			// prepareForSegue += performSegue
		} else {
			prepareForSegue = matchCases
		}
		return enumCases
	}

	func processViewControllers(storyboardCustomModules: Set<String>) -> [String] {
		var output = [String]()
		for scene in self.scenes {
			guard let viewController = scene.viewController,
				let customClass = viewController.customClass
			else { continue }

			let sceneSegues = scene.segues
			let sceneReusables = viewController.reusables(os)

			var seguesController = [String]()
			var prepareForSegue = [String]()
			let segues = processSegues(sceneSegues, customClass, &seguesController, &prepareForSegue)

			let sceneClass = processIdentifier(scene: scene, storyboardCustomModules: storyboardCustomModules)
			let sceneClass_noSegues = segues.isEmpty ? processIdentifier_noSegues(scene: scene, storyboardCustomModules: storyboardCustomModules) : []

			let reusables = processReusables(sceneReusables)

			if !segues.isEmpty || !reusables.isEmpty {
				output += "// MARK: - \(customClass)Scene"
				output += sceneClass_noSegues
				output += sceneClass

				output += seguesController
				output += ""

				output += "// MARK: - \(customClass)"
				if !segues.isEmpty {
					output += "extension \(customClass) {"
					output += "\tpublic struct Segue<Destination: UIViewController>: TypedSegue {"
					output += "\t\ttypealias Source = \(customClass)"
					output += "\t\tpublic let identifier: TypedSegue.Identifier?"
					output += "\t\tpublic let kind: SegueKind"
					output += "\t\tpublic let prepare: (Source, Destination, UIStoryboardSegue, Self) -> Void"
					output += ""
					
					output += "\t\tpublic var type: UIViewController.Type { Destination.self }"
					output += ""
					
					output += "\t\tpublic init(_ identifier: TypedSegue.Identifier? = nil, kind: SegueKind, "
					output += "\t\t\tprepare: @escaping (Source, Destination, UIStoryboardSegue, Self) -> Void = { _, _, _, _ in }) {"
					output += "\t\t\tself.identifier = identifier"
					output += "\t\t\tself.kind = kind"
					output += "\t\t\tself.prepare = prepare"
					output += "\t\t}"
					output += "\t}"
					output += ""

					output += "\tenum Segues {"
					output += segues
					output += "\t}"
					output += ""
					output += "\tfunc perform<Destination>(_ segue: Segue<Destination>)  {"
					output += "\t\tlet segueIdentifier = segue.identifier.require()"
					output += ""
					output += "\t\tperformSegue(withIdentifier: segueIdentifier) { [segueDescription = { String(reflecting: segue) }] storyboardSegue, _ in"
					output += "\t\t\tlet destination = storyboardSegue.destinationViewController(ofType: Destination.self)"
					output += "\t\t\t\t.require(\"\\(segueDescription()): expected destination view controller hierarchy to include \\(Destination.self)\")"
					output += ""
					output += "\t\t\tsegue.prepare(self, destination, storyboardSegue, segue)"
					output += "\t\t}"
					output += "\t}"
					output += ""
					output += "\tfunc perform<Destination>(_ segue: Segue<Destination>, "
					output += "\t\tprepare: @escaping (\(customClass), Destination, UIStoryboardSegue, Segue<Destination>) -> Void) {"
					output += "\t\tlet segueIdentifier = segue.identifier.require()"
					output += ""
					output += "\t\tperformSegue(withIdentifier: segueIdentifier) { [segueDescription = { String(reflecting: segue) }] storyboardSegue, _ in"
					output += "\t\t\tlet destination = storyboardSegue.destinationViewController(ofType: Destination.self)"
					output += "\t\t\t\t.require(\"\\(segueDescription()): expected destination view controller hierarchy to include \\(Destination.self)\")"
					output += ""
					output += "\t\t\tprepare(self, destination, storyboardSegue, segue)"
					output += "\t\t}"
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
						output += "\t\tstatic var \(swiftRepresentation(for: identifier, doNotShadow: reusable.customClass)) = Reusable(\"\(identifier)\", .\(reusable.kind), \(customClass).self)"
					} else {
						let customClass = os.reusableItemsMap[reusable.kind]
						output += "\t\tstatic var \(swiftRepresentation(for: identifier)) = Reusable(\"\(identifier)\", .\(reusable.kind), \(customClass!).self)"
					}
				}
			}
		}
		return output
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
