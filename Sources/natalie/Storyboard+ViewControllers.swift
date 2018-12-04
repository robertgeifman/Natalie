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

			let sourceIdString = sourceElement.xml.element?.attribute(by: "identifier")?.text
			let destinationIdString = destinationElement.attribute(by: "identifier")?.text

			let sourceId = sourceIdString == nil ? "nil" : "\"\(sourceIdString!)\""
			let destinationId = destinationIdString == nil ? "nil" : "\"\(destinationIdString!)\""

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

		delegateMethods += "@objc protocol \(customClass)SegueController: NSObjectProtocol {"

		matchPatternsHead += "\t\ttypealias RawValue = (String?, String?, String, String?, String)"
		matchPatternsHead += "\t\tinit?(rawValue: RawValue) {"
		matchPatternsHead += "\t\t\tswitch rawValue {"
		// here goes initWithRawValue
		matchPatterns += "\t\t\tdefault: self = .unmatchable"
		matchPatterns += "\t\t}"
		matchPatterns += ""
		matchPatterns += "\t\tvar rawValue: RawValue {"
		matchPatterns += "\t\t\tswitch self {"

		matchCases += "\toverride func prepare(for segue: NSStoryboardSegue, sender: Any?) {"
		matchCases += "\t\tguard let controller = segueController as? \(customClass)SegueController else { super.prepare(for: segue, sender: sender); return }"
		matchCases += "\t\tlet source = segue.sourceController as? NSUserInterfaceItemIdentification"
		matchCases += "\t\tlet destination = segue.destinationController as? NSUserInterfaceItemIdentification"
		matchCases += "\t\tlet pattern = (segue.identifier, source?.identifier?.rawValue, String(describing:type(of: segue.sourceController)),"
		matchCases += "\t\t\tdestination?.identifier?.rawValue, String(describing:type(of: segue.destinationController)))"
		matchCases += "\t\tswitch pattern {"

		for segue in segues {
			guard let sourceElement = segue.source.viewController,
				let sourceClass = sourceElement.customClass ?? os.controllerType(for: sourceElement.name),
				let source = sourceElement.storyboardIdentifier ?? sourceElement.id,
				let destination = segue.destination,
				let destinationElement = searchById(id: destination)?.element,
				let destinationClass = (destinationElement.attribute(by: "customClass")?.text ?? os.controllerType(for: destinationElement.name))
			else { continue }

			let sourceIdString = sourceElement.xml.element?.attribute(by: "identifier")?.text
			let destinationIdString = destinationElement.attribute(by: "identifier")?.text

			let sourceId = sourceIdString == nil ? "nil" : "\"\(sourceIdString!)\""
			let destinationId = destinationIdString == nil ? "nil" : "\"\(destinationIdString!)\""

			let sourceIdCase = sourceIdString == nil ? "_" : "\"\(sourceIdString!)\""
			let destinationIdCase = destinationIdString == nil ? "_" : "\"\(destinationIdString!)\""

			if let identifier = segue.identifier {
				let swiftIdentifier = swiftRepresentation(for: identifier, firstLetter: .lowercase)
				let functionName = "prepareFor" + swiftRepresentation(for: identifier, firstLetter: .capitalize)
				let pattern = "(\"\(identifier)\", \(sourceId), \"\(sourceClass)\", \(destinationId), \"\(destinationClass)\")"
				if let value = patterns[pattern], value > 1 {
					continue
				}
				matchPatterns += "\t\t\tcase .\(swiftIdentifier): return (\"\(identifier)\", \(sourceId), \"\(sourceClass)\", \(destinationId), \"\(destinationClass)\")"

				delegateMethods += "\t@objc optional func \(functionName)(sender: Any?)"
				enumCases += "\t\tcase \(swiftIdentifier) = \"\(identifier)\" // \(destinationElement.name)"
				matchCases += "\t\tcase (\"\(identifier)\", \(sourceIdCase), \"\(sourceClass)\", \(destinationIdCase), \"\(destinationClass)\"): controller.\(functionName)?(sender: sender)"
				initWithRawValue += "\t\t\tcase (_, \(sourceIdCase), \"\(sourceClass)\", \(destinationIdCase), \"\(destinationClass)\"): self = .\(swiftIdentifier)"
			} else if segue.kind == "embed" {
				let sourceName = swiftRepresentation(for: source, firstLetter: .capitalize)
				let destinationName = swiftRepresentation(for: destinationIdString ?? destination, firstLetter: .capitalize)
				let swiftIdentifier = segue.kind + swiftRepresentation(for: destinationElement.name, firstLetter: .capitalize) +
					swiftRepresentation(for: destinationIdString ?? destination, firstLetter: .capitalize)
				let functionName = "prepareFor" + swiftRepresentation(for: segue.kind, firstLetter: .capitalize) +
					swiftRepresentation(for: destinationElement.name, firstLetter: .capitalize) + destinationName

				let pattern = "(nil, \(sourceId), \"\(sourceClass)\", \(destinationId), \"\(destinationClass)\")"
				if let value = patterns[pattern], value > 1 {
					continue
				}
				matchPatterns += "\t\t\tcase .\(swiftIdentifier): return (\"nil\", \(sourceId), \"\(sourceClass)\", \(destinationId), \"\(destinationClass)\") //  sourceName=\"\(sourceName)\""

				delegateMethods += "\t@objc optional func \(functionName)(sender: Any?)"
				enumCases += "\t\tcase \(swiftIdentifier) = \"\(destination)\" // \(segue.id) - \(destinationElement.name) - \(destination) "
				matchCases += "\t\tcase (_, \(sourceIdCase), \"\(sourceClass)\", \(destinationIdCase), \"\(destinationClass)\"): controller.\(functionName)?(sender: sender)"
				initWithRawValue += "\t\t\tcase (_, \(sourceIdCase), \"\(sourceClass)\", \(destinationIdCase), \"\(destinationClass)\"): self = .\(swiftIdentifier)"
			} else if segue.kind == "relationship" {
				let sourceName = swiftRepresentation(for: source, firstLetter: .capitalize)
				let destinationName = swiftRepresentation(for: destinationIdString ?? destination, firstLetter: .capitalize)
				let relationshipKind = destinationElement.attribute(by: "relationship")?.text
				let swiftIdentifier = (relationshipKind ?? segue.kind) + swiftRepresentation(for: destinationElement.name, firstLetter: .capitalize) +
					swiftRepresentation(for: destinationIdString ?? destination, firstLetter: .capitalize)
				let functionName = "prepareFor" + swiftRepresentation(for: segue.kind, firstLetter: .capitalize) +
					swiftRepresentation(for: destinationElement.name, firstLetter: .capitalize) + destinationName

				let pattern = "(nil, \(sourceId), \"\(sourceClass)\", \(destinationId), \"\(destinationClass)\")"
				if let value = patterns[pattern], value > 1 {
					continue
				}
				matchPatterns += "\t\t\tcase .\(swiftIdentifier): return (\"nil\", \(sourceId), \"\(sourceClass)\", \(destinationId), \"\(destinationClass)\") //  relationship=\"\(relationshipKind!)\", sourceName=\"\(sourceName)\""

				delegateMethods += "\t@objc optional func \(functionName)(sender: Any?)"
				enumCases += "\t\tcase \(swiftIdentifier) = \"\(destination)\" // \(segue.id) - \(destinationElement.name) - \(destination) "
				matchCases += "\t\tcase (_, \(sourceIdCase), \"\(sourceClass)\", \(destinationIdCase), \"\(destinationClass)\"): controller.\(functionName)?(sender: sender)"
				initWithRawValue += "\t\t\tcase (_, \(sourceIdCase), \"\(sourceClass)\", \(destinationIdCase), \"\(destinationClass)\"): self = .\(swiftIdentifier)"
			}
		}

		if enumCases.isEmpty {
			return [String]()
		}

		delegateMethods += "}"

		matchPatterns += "\t\t\tcase .unmatchable: return (\"noID\", \"noSourceID\", \"invalidType\", \"noDestinationID\", \"invalidType\")"
		matchPatterns += "\t\t\t}"
		matchPatterns += "\t\t}"

		matchPatternsHead += initWithRawValue
		matchPatternsHead += matchPatterns

		matchCases += "\t\tdefault: super.prepare(for: segue, sender: sender)"
		matchCases += "\t\t}"
		matchCases += "\t}"

		enumCases += "\t\tcase unmatchable"
		enumCases += ""
		enumCases += matchPatternsHead

		seguesController = delegateMethods
		prepareForSegue = matchCases
		return enumCases
	}
}
