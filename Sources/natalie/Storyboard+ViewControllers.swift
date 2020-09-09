//
//  Storyboard+Natalie.swift
//  Natalie
//
//  Created by Eric Marchand on 06/06/2017.
//  Copyright © 2017 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

extension Storyboard {
	// MARK: - View Controllers
	func processViewControllers(storyboardCustomModules: inout Set<String>) -> [String] {
		var output = [String]()
		for scene in self.scenes {
			guard let viewController = scene.viewController,
				let customClass = viewController.customClass
			else { continue }

			let sceneSegues = scene.segues
			let sceneReusables = viewController.reusables(os)

			var seguesController = [String]()
			var prepareForSegue = [String]()
			let segues = processSegues(sceneSegues, customClass, &seguesController, &prepareForSegue, storyboardCustomModules: &storyboardCustomModules)
			let reusables = processReusables(sceneReusables)

			let sceneClass = processIdentifier(scene: scene, storyboardCustomModules: storyboardCustomModules)
			let sceneClass_noSegues = (seguesController.isEmpty) ? processIdentifier_noSegues(scene: scene, storyboardCustomModules: storyboardCustomModules) : []

			if !segues.isEmpty || !reusables.declarations.isEmpty {
				output += "// MARK: - \(customClass)Scene"
				output += sceneClass_noSegues
				output += sceneClass

				output += seguesController
				output += ""

				output += "// MARK: - \(customClass)"
				if !segues.isEmpty {
					output += "extension \(customClass) {"
					output += "\t" + "enum Segues {"
					output += segues
					output += "\t" + "}"
					output += ""
					output += "\t" + "@inline(__always)"
					output += "\t" + "func perform<Kind: UIStoryboardSegue, To: UIViewController>(_ segue: Segue<Kind, To>) { segue.perform(from: self) }"
					output += ""
				} else {
					output += "extension \(customClass) {"
				}

				if !reusables.declarations.isEmpty {
					output += "\tenum Reusables {"
					output += "\t\ttypealias Reusables = Self"
					output.append(contentsOf: processReusableCases(reusables.cases))
					output.append(contentsOf: reusables.declarations)
					output += "\t}"
				}

				if !segues.isEmpty && !reusables.declarations.isEmpty {
					output += ""
				}

				output += prepareForSegue
				output += "}"
			}

			output += ""
		}
		return output
	}

	// MARK: - Segues
	func processSegues(_ sceneSegues: [Segue]?, _ customClass: String, _ seguesController: inout [String],
		_ prepareForSegue: inout [String], storyboardCustomModules: inout Set<String>) -> [String] {
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

		var hasIdentifiableSegues = false
		for segue in segues {
			guard let srcElement = segue.source.viewController else { continue }
			guard let srcClass = srcElement.customClass ?? os.controllerType(for: srcElement.name) else { continue }
			guard let dstID = segue.destination else { continue }
			guard let dstElement = searchById(id: dstID)?.element else { continue }
			
			if segue.kind == "unwind" {
				if let segueID = segue.identifier, !segueID.isEmpty {
					let dstName: String = swiftRepresentation(for: segueID, firstLetter: .capitalize)
					let segueIdentifier: String? = segueID

					let segueName = dstName.first!.lowercased() + dstName.dropFirst()

					if let segueIdentifier = segueIdentifier {
						allCases += "\t\t\t\(segueName),"
						seguePatterns += "\t\tstatic let \(segueName) = Segue<UIStoryboardSegue, UIViewController>(identifier: \"\(segueIdentifier)\")"
					}

					numberOfCases += 1
					continue
				}
			}

			guard let dstClass = (dstElement.attribute(by: "customClass")?.text ?? os.controllerType(for: dstElement.name)) else { continue }

			// let srcStoryboardID = srcElement.xml.element?.attribute(by: "storyboardIdentifier")?.text
			let dstStoryboardID = dstElement.attribute(by: "storyboardIdentifier")?.text

			let pattern = "(\(segue.identifier.unwrappedString), \(dstStoryboardID.unwrappedString), \(dstClass).self)"

//			let srcCastUnwind = (srcClass == "UIViewController"||srcClass == "NSViewController") ? "_" : "is \(srcClass).Type"
			let dstCast = (dstClass == "UIViewController"||dstClass == "NSViewController") ? "_" : "is \(dstClass).Type"
			let dstCastUnwind = (dstClass == "UIViewController"||dstClass == "NSViewController") ? "_" : "is \(dstClass)"
			// let srcRef = (srcClass == "UIViewController"||srcClass == "NSViewController") ? "_" : "\(srcStoryboardID.unwrappedPattern)"
			let dstRef = (dstClass == "UIViewController"||dstClass == "NSViewController") ? "_" : "\(dstStoryboardID.unwrappedPattern)"
			if let value = patterns[pattern], value > 1 {
				continue
			}

			guard let segueID = segue.identifier, !segueID.isEmpty else {
				continue
			}
			
			if segue.kind != "embed", segue.kind != "relationship" {
				hasIdentifiableSegues = true // hasIdentifiableSegues || (segue.kind != "embed" && segue.kind != "relationship")
				let swiftIdentifier = swiftRepresentation(for: segueID, firstLetter: .lowercase)
				let dstName = swiftRepresentation(for: segueID, firstLetter: .capitalize)

				let segueName = dstName.first!.lowercased() + dstName.dropFirst()

//				let casePattern = "(Segues.\(segueName).identifier, \(dstRef), \(dstCast))"
				let casePattern = "(Segues.\(segueName).identifier, \(dstCast))"
		
				let functionName = "prepareForSegue" + dstName

				if segue.kind == "custom" {
					if let customSegueClassAttr = segue.xml.element?.attribute(by: "customClass") {
						let customSegueClass = customSegueClassAttr.text
						if let customModule = segue.xml.element?.attribute(by: "customModule")?.text {
							storyboardCustomModules.insert(customModule)
						}
						 
						let method = "\(functionName)(_ destination: \(dstClass), sender: Any?, segue: \(customSegueClass))"

						seguePatterns += "\t\tstatic let \(segueName) = Segue<\(customSegueClass), \(dstClass)>(identifier: \"\(segueID)\")"//, segueKind: .\(segue.kind))"

						delegateMethods += "\tfunc " + method

						defaultImplementation += "\tfunc " + method + " {"
//						defaultImplementation += "\t\tprint(\"\(customClass).\(method)\")"
						defaultImplementation += "\t}"

						matchCases += "\t\tcase \(casePattern):"
						if dstCast == "_" {
							matchCases += "\t\t\tsceneCoordinator.\(functionName)(segue.destinationController, sender: sender, segue: (segue as? \(customSegueClass)).require())"
						} else {
							matchCases += "\t\t\tlet dst = (segue.destinationController as? \(dstClass)).require()"
							matchCases += "\t\t\tsceneCoordinator.\(functionName)(dst, sender: sender, segue: (segue as? \(customSegueClass)).require())"
						}
					} else {
						seguePatterns += "\t\t#error(\"no custom class set for segue \(segueName) to \(dstClass) (\(segueID))\")"
					}
				} else {
					let method = "\(functionName)(_ destination: \(dstClass), sender: Any?, segue: UIStoryboardSegue)"

					seguePatterns += "\t\tstatic let \(segueName) = Segue<UIStoryboardSegue, \(dstClass)>(identifier: \"\(segueID)\")"//, segueKind: .\(segue.kind))"

					delegateMethods += "\tfunc " + method

					defaultImplementation += "\tfunc " + method + " {"
//					defaultImplementation += "\t\tprint(\"\(customClass).\(method)\")"
					defaultImplementation += "\t}"

					matchCases += "\t\tcase \(casePattern):"
					if dstCast == "_" {
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(segue.destinationController, sender: sender, segue: segue)"
					} else {
						matchCases += "\t\t\tlet dst = (segue.destinationController as? \(dstClass)).require()"
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(dst, sender: sender, segue: segue)"
					}
				}

				allCases += "\t\t\t\(segueName),"

				let canPerformFunctionName = "canPerformSegue" + dstName
				let canPerformMethod = "\(canPerformFunctionName)(sender: Any?) -> Bool"

				let canUnwindFunctionName = "canUnwind" + dstName
//				let canUnwindMethod = "\(canUnwindFunctionName)(from: \(dstClass), sender: Any?) -> Bool"
				let canUnwindMethod = "\(canUnwindFunctionName)(from: UIViewController, sender: Any?) -> Bool"

				let unwindFunctionName = "unwind" + dstName
//				let unwindMethod = "\(unwindFunctionName)(from: \(dstClass), to: \(srcClass))"
				let unwindMethod = "\(unwindFunctionName)(from: UIViewController, to: UIViewController)"

				delegateMethods += "\tfunc " + canPerformMethod
				delegateMethods += "\tfunc " + canUnwindMethod
				delegateMethods += "\tfunc " + unwindMethod

				defaultImplementation += "\tfunc " + canPerformMethod + " {"
//				defaultImplementation += "\t\tprint(\"\(customClass).\(canPerformMethod)\"); return true"
				defaultImplementation += "\t\treturn true"
				defaultImplementation += "\t}"

				defaultImplementation += "\tfunc " + canUnwindMethod + " {"
//				defaultImplementation +=  "\t\tprint(\"\(customClass).\(canUnwindMethod)\"); return true"
				defaultImplementation += "\t\treturn true"
				defaultImplementation += "\t}"

				defaultImplementation += "\tfunc " + unwindMethod + " {"
//				defaultImplementation +=  "\t\tprint(\"\(customClass).\(unwindMethod)\")"
				defaultImplementation += "\t}"

				unwindMethods += "\t@IBAction func \(unwindFunctionName)(segue: UIStoryboardSegue) {"
				
				unwindMethods += "\t\tlet source = segue.source"
				unwindMethods += "\t\tlet destination = segue.destination"
//				if dstCastUnwind == "_" {
//					unwindMethods += "\t\tlet source = segue.source"
//				} else {
//					unwindMethods += "\t\tguard let source = segue.source as? \(dstClass) else { return }"
//				}
//
//				if srcCastUnwind == "_" {
//					unwindMethods += "\t\tlet destination = segue.destination"
//				} else {
//					unwindMethods += "\t\tguard let destination = segue.destination as? \(srcClass) else { return }"
//				}
				
				unwindMethods += "\t\tsceneCoordinator.\(unwindFunctionName)(from: source, to: destination)"
				unwindMethods += "\t}"
				unwindMethods += ""

				numberOfCases += 1

				canMatchCases += "\t\tcase Segues.\(segueName).identifier:"
				canMatchCases += "\t\t\treturn sceneCoordinator.\(canPerformFunctionName)(sender: sender)"

				initWithRawValue += "\t\t\tcase \(casePattern): self = .\(swiftIdentifier)"
				
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
//					"(_, \(dstRef), \(dstCast))" :
//					"(Segues.\(segueName).identifier, \(dstRef), \(dstCast))"
					"(_, \(dstCast))" :
					"(Segues.\(segueName).identifier, \(dstCast))"
					
				let swiftIdentifier = "present" + dstName
				let functionName = "prepareToPresent" + dstName
				let method = "\(functionName)(_ destination: \(dstClass), sender: Any?, segue: UIStoryboardSegue)"

				if let segueIdentifier = segueIdentifier {
					allCases += "\t\t\t\(segueName),"
					seguePatterns += "\t\tstatic let \(segueName) = Segue<UIStoryboardSegue, \(dstClass)>(identifier: \"\(segueIdentifier)\")"//, segueKind: .\(segue.kind))"
				}

				if dstCast != dstRef {
					numberOfCases += 1
					delegateMethods += "\tfunc " + method
					defaultImplementation += "\tfunc " + method + " {"
//					defaultImplementation += "\t\tprint(\"\(customClass).\(method)\")"
					defaultImplementation += "\t}"

					matchCases += "\t\tcase \(casePattern):"
					if dstCast == "_" {
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(segue.destinationController, sender: sender, segue: segue)"
					} else {
						matchCases += "\t\t\tlet dst = (segue.destinationController as? \(dstClass)).require()"
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(dst, sender: sender, segue: segue)"
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
//					"(_, \(dstRef), \(dstCast))" :
//					"(Segues.\(segueName).identifier, \(dstRef), \(dstCast))"
					"(_,\(dstCast))" :
					"(Segues.\(segueName).identifier,\(dstCast))"

				let swiftIdentifier = "embed" + dstName
				let functionName = "prepareToEmbed" + dstName
				let method = "\(functionName)(_ destination: \(dstClass), sender: Any?, segue: UIStoryboardSegue)"

				if let segueIdentifier = segueIdentifier {
					allCases += "\t\t\t\(segueName),"
					seguePatterns += "\t\tstatic let \(segueName) = Segue<UIStoryboardSegue, \(dstClass)>(identifier: \"\(segueIdentifier)\")"//, segueKind: .\(segue.kind))"
				}

				if dstCast != dstRef {
					numberOfCases += 1
					delegateMethods += "\tfunc " + method
					defaultImplementation += "\tfunc " + method + " {"
//					defaultImplementation += "\t\tprint(\"\(customClass).\(method)\")"
					defaultImplementation += "\t}"

					matchCases += "\t\tcase \(casePattern):"
					if dstCast == "_" {
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(segue.destinationController, sender: sender, segue: segue)"
					} else {
						matchCases += "\t\t\tlet dst = (segue.destinationController as? \(dstClass)).require()"
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(dst, sender: sender, segue: segue)"
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
//					"(_, \(dstRef), \(dstCast))" :
//					"(Segues.\(segueName).identifier, \(dstRef), \(dstCast))"
					"(_, \(dstCast))" :
					"(Segues.\(segueName).identifier, \(dstCast))"

				let swiftIdentifier = "relationship" + dstName
				let functionName = "prepareRelationship" + dstName
				let method = "\(functionName)(_ destination: \(dstClass), sender: Any?, segue: UIStoryboardSegue)"

				if let segueIdentifier = segueIdentifier {
					allCases += "\t\t\t\(segueName),"
					seguePatterns += "\t\tstatic let \(segueName) = Segue<UIStoryboardSegue, \(dstClass)>(identifier: \"\(segueIdentifier)\")"//, segueKind: .\(segue.kind))"
				}
				
				if dstCast != dstRef {
					numberOfCases += 1
					delegateMethods += "\tfunc " + method
					defaultImplementation += "\tfunc " + method + " {"
//					defaultImplementation += "\t\tprint(\"\(customClass).\(method)\")"
					defaultImplementation += "\t}"	

					matchCases += "\t\tcase \(casePattern):"
					if dstCast == "_" {
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(segue.destinationController, sender: sender, segue: segue)"
					} else {
						matchCases += "\t\t\tlet dst = (segue.destinationController as? \(dstClass)).require()"
						matchCases += "\t\t\tsceneCoordinator.\(functionName)(dst, sender: sender, segue: segue)"
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

		// tweaked so that 13.* does not give me grief
		canUnwindCases.insert("\t@available(iOS 13, *)", at: 0)
		canUnwindCases.insert("\toverride func canPerformUnwindSegueAction(_ action: Selector, from: UIViewController, sender: Any?) -> Bool {", at: 1)
		canUnwindCases.insert("\t\tswitch (action, from) {", at: 2)

		canUnwindCases += "\t\tdefault:"
		canUnwindCases += "\t\t\treturn super.canPerformUnwindSegueAction(action, from: from, sender: sender)"
		canUnwindCases += "\t\t}"
		canUnwindCases += "\t}"
		
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
	
	// MARK: - Reusables
	func processReusables(_ sceneReusables: [Reusable]?) -> (declarations: [String], cases: [(String, String, String)]) {
		var declarations = [String]()
		var allCases = [(String, String, String)]()
		guard let reusables = sceneReusables, !reusables.isEmpty else { return (declarations: [], cases: []) }

		for reusable in reusables {
			guard let identifier = reusable.reuseIdentifier else { continue }
			let customClass = reusable.customClass ?? os.reusableItemsMap[reusable.kind]!
			let swiftIdentifier = swiftRepresentation(for: identifier, firstLetter: .capitalize)
			let reusableIdentifier = swiftIdentifier.first!.lowercased() + swiftIdentifier.dropFirst()
			if reusable.kind == "collectionReusableView" {
				if reusable.key == "sectionHeaderView" {
					declarations += "\t\tstatic var \(reusableIdentifier) = Reusable<\(customClass)>(header: \"\(identifier)\")"
				} else if reusable.key == "sectionFooterView" {
					declarations += "\t\tstatic var \(reusableIdentifier) = Reusable<\(customClass)>(footer: \"\(identifier)\")"
				} else {
					declarations += "\t\tstatic var \(reusableIdentifier) = Reusable<\(customClass)>(\"\(identifier)\", elementKind: reusable.key)"
				}
			} else {
				declarations += "\t\tstatic var \(reusableIdentifier) = Reusable<\(customClass)>(\"\(identifier)\", kind: .\(reusable.kind))"
			}
			allCases.append((reusable.kind, reusableIdentifier, reusable.key))
		}
		return (declarations: declarations, cases: allCases)
	}
	func processReusableCases(_ cases: [(String, String, String)]) -> [String] {
		var output = [String]()
		let table = Dictionary(grouping: cases) { $0.0 }
#if true
		output.append(contentsOf: processCollectionView(values: table))
		output.append(contentsOf: processTableView(values: table))
#else
		for (key, values) in table {
			switch key {
			case "collectionReusableView": output.append(contentsOf: processReusableViews(key: key, values: values))
			case "collectionViewCell": output.append(contentsOf: processCells(key: key, values: values))
			case "tableViewCell": output.append(contentsOf: processTableCells(key: key, values: values))
			default: continue
			}
		}
#endif
		return output
	}

	func processCollectionView(values: [String: [(String, String, String)]]) -> [String] {
		var output = [String]()
		output += "\t\t" + "struct Prototypes: CollectionViewPrototypes {"
		output += "\t\t\t" + "typealias Kind = UICollectionView"
		output += "\t\t\t" + "static var cells: [ReusableProtocol] = ["
		if let reusables = values["collectionViewCell"] {
			output += "\t\t\t\t" + reusables.map { $0.1 }.joined(separator: ", ")
		}
		output += "\t\t\t" + "]"
		output += "\t\t\t" + "static var reusableViews: [ReusableProtocol] = ["
		if let reusables = values["collectionReusableView"] {
			output += "\t\t\t\t" + reusables.map { $0.1 }.joined(separator: ", ")
		}
		output += "\t\t\t" + "]"
		output += "\t\t\t" + "let cells: [String: UICollectionViewCell]"
		output += "\t\t\t" + "let reusableViews: [String: UICollectionReusableView]"
		output += ""
		output += "\t\t\t" + "init(collectionView: UICollectionView) {"
		output += "\t\t\t\t" + "var cells = [String: UICollectionViewCell]()"
		output += "\t\t\t\t" + "var reusableViews = [String: UICollectionReusableView]()"
		output += "\t\t\t\t" + "for reusable in Self.cells {"
		output += "\t\t\t\t\t" + "cells[reusable.identifier] = collectionView.dequeueReusableCell(withReuseIdentifier: reusable.identifier, for: IndexPath())"
		output += "\t\t\t\t" + "}"
		output += "\t\t\t\t" + "for reusable in Self.reusableViews {"
		output += "\t\t\t\t\t" + "reusableViews[reusable.identifier] = collectionView.dequeueReusableSupplementaryView("
		output += "\t\t\t\t\t\t" + "ofKind: reusable.elementKind, withReuseIdentifier: reusable.identifier, for: IndexPath())"
		output += "\t\t\t\t" + "}"
		output += "\t\t\t\t" + "self.cells = cells"
		output += "\t\t\t\t" + "self.reusableViews = reusableViews"
		output += "\t\t\t}"
		output += "\t\t\t" + "subscript<Content>(reusable: Reusable<Content>) -> Content"
		output += "\t\t\t\t" + "where Content: UICollectionViewCell {"
		output += "\t\t\t\t" + "(cells[reusable.identifier] as? Content).require(\"No prorotype for \\(reusable)\")"
		output += "\t\t\t" + "}"

		output += "\t\t\t" + "subscript<Content>(reusable: Reusable<Content>) -> Content"
		output += "\t\t\t\t" + "where Content: UICollectionReusableView {"
		output += "\t\t\t\t" + "(reusableViews[reusable.identifier] as? Content).require(\"No prorotype for \\(reusable)\")"
		output += "\t\t\t" + "}"
		output += "\t\t}"
		return output
	}
	func processTableView(values: [String: [(String, String, String)]]) -> [String] {
		var output = [String]()
		output += "\t\t" + "struct TablePrototypes: TableViewPrototypes {"
		output += "\t\t\t" + "typealias Kind = UITableView"
		output += "\t\t\t" + "static var cells: [ReusableProtocol] = ["
		if let reusables = values["tableViewCell"] {
			output += "\t\t\t\t" + reusables.map { $0.1 }.joined(separator: ", ")
		}
		output += "\t\t\t" + "]"
		output += "\t\t\t" + "static var reusableViews: [ReusableProtocol] = ["
		if let reusables = values["tableViewHeaderFooterView"] {
			output += "\t\t\t\t" + reusables.map { $0.1 }.joined(separator: ", ")
		}
		output += "\t\t\t" + "]"
		output += "\t\t\t" + "let cells: [String: UITableViewCell]"
		output += "\t\t\t" + "let reusableViews: [String: UITableViewHeaderFooterView]"
		output += ""
		output += "\t\t\t" + "init(tableView: UITableView) {"
		output += "\t\t\t\t" + "var cells = [String: UITableViewCell]()"
		output += "\t\t\t\t" + "var reusableViews = [String: UITableViewHeaderFooterView]()"
		output += "\t\t\t\t" + "for reusable in Self.cells {"
		output += "\t\t\t\t\t" + "cells[reusable.identifier] = tableView.dequeueReusableCell(withIdentifier: reusable.identifier, for: IndexPath())"
		output += "\t\t\t\t" + "}"
		output += "\t\t\t\t" + "for reusable in Self.reusableViews {"
		output += "\t\t\t\t\t" + "reusableViews[reusable.identifier] = tableView.dequeueReusableHeaderFooterView(withIdentifier: reusable.identifier)"
		output += "\t\t\t\t" + "}"
		output += "\t\t\t\t" + "self.cells = cells"
		output += "\t\t\t\t" + "self.reusableViews = reusableViews"
		output += "\t\t\t}"
		output += "\t\t\t" + "subscript<Content>(reusable: Reusable<Content>) -> Content"
		output += "\t\t\t\t" + "where Content: UITableViewCell {"
		output += "\t\t\t\t" + "(cells[reusable.identifier] as? Content).require(\"No prorotype for \\(reusable)\")"
		output += "\t\t\t" + "}"

		output += "\t\t\t" + "subscript<Content>(reusable: Reusable<Content>) -> Content"
		output += "\t\t\t\t" + "where Content: UITableViewHeaderFooterView {"
		output += "\t\t\t\t" + "(reusableViews[reusable.identifier] as? Content).require(\"No prorotype for \\(reusable)\")"
		output += "\t\t\t" + "}"
		output += "\t\t}"
		return output
	}
	
	func processCells(key: String, values: [(String, String, String)]) -> [String] {
		var output = [String]()
		output += "\t\t" + "struct Cells: PrototypeCollection {"
		output += "\t\t\t" + "typealias Kind = UICollectionViewCell"
		output += "\t\t\t" + "static var reusables: [ReusableProtocol] = ["
		output += "\t\t\t\t" + values.map { $0.1 }.joined(separator: ", ")
		output += "\t\t\t" + "]"
		output += "\t\t\t" + "let prototypes: [String: Kind]"
		output += ""
		output += "\t\t\t" + "init(collectionView: UICollectionView) {"
		output += "\t\t\t\t" + "var prototypes = [String: Kind]()"
		output += "\t\t\t\t" + "for reusable in Self.reusables {"
		output += "\t\t\t\t\t" + "prototypes[reusable.identifier] = collectionView.dequeueReusableCell(withReuseIdentifier: reusable.identifier, for: IndexPath())"
		output += "\t\t\t\t" + "}"
		output += "\t\t\t\t" + "self.prototypes = prototypes"
		output += "\t\t\t}"
		output += "\t\t}"
		return output
	}
	func processReusableViews(key: String, values: [(String, String, String)]) -> [String] {
		var output = [String]()
		output += "\t\t" + "struct ReusableViews: PrototypeCollection {"
		output += "\t\t\t" + "typealias Kind = UICollectionReusableView"
		output += "\t\t\t" + "static var reusables: [ReusableProtocol] = ["
		output += "\t\t\t\t" + values.map { $0.1 }.joined(separator: ", ")
		output += "\t\t\t" + "]"
		output += "\t\t\t" + "let prototypes: [String: Kind]"
		output += ""
		output += "\t\t\t" + "init(collectionView: UICollectionView) {"
		output += "\t\t\t\t" + "var prototypes = [String: Kind]()"
		output += "\t\t\t\t" + "for reusable in Self.reusables {"
		output += "\t\t\t\t\t" + "prototypes[reusable.identifier] = collectionView.dequeueReusableSupplementaryView("
		output += "\t\t\t\t\t\t" + "ofKind: reusable.elementKind, withReuseIdentifier: reusable.identifier, for: IndexPath())"
		output += "\t\t\t\t" + "}"
		output += "\t\t\t\t" + "self.prototypes = prototypes"
		output += "\t\t\t}"
		output += "\t\t}"
		return output
	}
	func processTableCells(key: String, values: [(String, String, String)]) -> [String] {
		var output = [String]()
		output += "\t\t" + "struct TableCells: PrototypeCollection {"
		output += "\t\t\t" + "typealias Kind = UITableViewCell"
		output += "\t\t\t" + "static var reusables: [ReusableProtocol] = ["
		output += "\t\t\t\t" + values.map { $0.1 }.joined(separator: ", ")
		output += "\t\t\t" + "]"
		output += "\t\t\t" + "let prototypes: [String: Kind]"
		output += ""
		output += "\t\t\t" + "init(tableView: UITableView) {"
		output += "\t\t\t\t" + "var prototypes = [String: Kind]()"
		output += "\t\t\t\t" + "for reusable in Self.reusables {"
		output += "\t\t\t\t\t" + "prototypes[reusable.identifier] = tableView.dequeueReusableCell(withIdentifier: reusable.identifier, for: IndexPath())"
		output += "\t\t\t\t" + "}"
		output += "\t\t\t\t" + "self.prototypes = prototypes"
		output += "\t\t\t}"
		output += "\t\t}"
		return output
	}
	func processHeaderFooterViews(key: String, values: [(String, String, String)]) -> [String] {
		var output = [String]()
		output += "\t\t" + "struct ReusableTableViews: PrototypeCollection {"
		output += "\t\t\t" + "typealias Kind = UITableCell"
		output += "\t\t\t" + "static var reusables: [ReusableProtocol] = ["
		output += "\t\t\t\t" + values.map { $0.1 }.joined(separator: ", ")
		output += "\t\t\t" + "]"
		output += "\t\t\t" + "let prototypes: [String: Kind]"
		output += ""
		output += "\t\t\t" + "init(tableView: UITableView) {"
		output += "\t\t\t\t" + "var prototypes = [String: Kind]()"
		output += "\t\t\t\t" + "for reusable in Self.reusables {"
		output += "\t\t\t\t\t" + "prototypes[reusable.identifier] = tableView.dequeueReusableHeaderFooterView(withIdentifier: reusable.identifier)"
		output += "\t\t\t\t" + "}"
		output += "\t\t\t\t" + "self.prototypes = prototypes"
		output += "\t\t\t}"
		output += "\t\t}"
		return output
	}
}
