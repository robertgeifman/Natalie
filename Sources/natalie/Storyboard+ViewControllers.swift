//
//  Storyboard+Natalie.swift
//  Natalie
//
//  Created by Eric Marchand on 06/06/2017.
//  Copyright © 2017 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

struct NavSegue {
	let dstID: String
	let dstController: ViewController
	let rootSegue: Segue
	let rootController: ViewController
	let segueID: String
	let dstName: String
	let rootClass: String
	let segueName: String
	let customSegueClass: String
}

extension Storyboard {
	// MARK: - View Controllers
	func processViewControllers(storyboardCustomModules: inout Set<String>) -> [String] {
		var output = [String]()
		var viewControllers = [String: ViewController]()
		for vc in scenes {
			if let id = vc.viewController?.id { viewControllers[id] = vc.viewController }
		}
		for scene in self.scenes {
			guard let viewController = scene.viewController,
				let customClass = viewController.customClass
			else { continue }

			let sceneSegues = scene.segues
			let sceneReusables = viewController.reusables(os)

			var seguesController = [String]()
			var prepareForSegue = [String]()
			let segues = processSegues(viewControllers, scene, sceneSegues, customClass, &seguesController, &prepareForSegue, storyboardCustomModules: &storyboardCustomModules)
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
#if false
					output += "\t" + "@inline(__always)"
					output += "\t" + "func perform<Kind: UIStoryboardSegue, To: UIViewController>(_ segue: Segue<Kind, To>) { segue.perform(from: self) }"
					output += "\t" + "@inline(__always)"
					output += "\t" + "func perform<Kind: UIStoryboardSegue, To: UIViewController>(_ segue: Segue<Kind, To>, "
					output += "\t\t" + "prepare body: @escaping (Kind, To) -> Void) {"
					output += "\t\t" + "segue.perform(from: self, prepare: body)"
					output += "\t" + "}"
					output += "\t" + "@inline(__always)"
					output += "\t" + "func perform<To: UIViewController>(_ segue: Segue<UIStoryboardSegue, To>) { "
					output += "\t\t" + "segue.perform(from: self)"
					output += "\t" + "}"
					output += "\t" + "@inline(__always)"
					output += "\t" + "func perform<To: UIViewController>(_ segue: Segue<UIStoryboardSegue, To>, "
					output += "\t\t" + "prepare body: @escaping (To) -> Void) {"
					output += "\t\t" + "segue.perform(from: self, prepare: body)"
					output += "\t" + "}"
					output += "\t" + "@inline(__always)"
					output += "\t" + "func perform<Kind, To, Root>(_ segue: NavigationSegue<Kind, To, Root>) "
					output += "\t\t" + "where Kind: UIStoryboardSegue, To: UINavigationController, Root: UIViewController { "
					output += "\t\t" + "segue.perform(from: self)"
					output += "\t" + "}"
					output += "\t" + "@inline(__always)"
					output += "\t" + "func perform<Kind, To, Root>(_ segue: NavigationSegue<Kind, To, Root>, "
					output += "\t\t" + "prepare body: @escaping (Kind, To) -> Void)"
					output += "\t\t" + "where Kind: UIStoryboardSegue, To: UINavigationController, Root: UIViewController { "
					output += "\t\t" + "segue.perform(from: self) { kind, to, _ in body(kind, to) }"
					output += "\t" + "}"
					output += "\t" + "@inline(__always)"
					output += "\t" + "func perform<Kind, To, Root>(_ segue: NavigationSegue<Kind, To, Root>, "
					output += "\t\t" + "prepare body: @escaping (Kind, To, Root) -> Void)"
					output += "\t\t" + "where Kind: UIStoryboardSegue, To: UINavigationController, Root: UIViewController { "
					output += "\t\t" + "segue.perform(from: self, prepare: body)"
					output += "\t" + "}"

					output += "\t" + "@inline(__always)"
					output += "\t" + "func perform<To, Root>(_ segue: NavigationSegue<UIStoryboardSegue, To, Root>, "
					output += "\t\t" + "prepare body: @escaping (To) -> Void)"
					output += "\t\t" + "where To: UINavigationController, Root: UIViewController { "
					output += "\t\t" + "segue.perform(from: self) { _, to, _ in body(to) }"
					output += "\t" + "}"
					output += "\t" + "@inline(__always)"
					output += "\t" + "func perform<To, Root>(_ segue: NavigationSegue<UIStoryboardSegue, To, Root>, "
					output += "\t\t" + "prepare body: @escaping (To, Root) -> Void)"
					output += "\t\t" + "where To: UINavigationController, Root: UIViewController { "
					output += "\t\t" + "segue.perform(from: self) { body($1, $2) }"
					output += "\t" + "}"
					output += ""
#endif
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

			if !output.isEmpty { output += "" }
		}
		return output
	}

	// MARK: - Segues
	func processSegues(_ viewControllers: [String: ViewController], _ scene: Scene, _ sceneSegues: [Segue]?, _ customClass: String, _ seguesController: inout [String], _ prepareForSegue: inout [String], storyboardCustomModules: inout Set<String>) -> [String] {
		guard let segues = sceneSegues, !segues.isEmpty else { return [String]() }

		var patterns = [String: Int]()

		for segue in segues {
			guard
//				let srcElement = segue.source.viewController,
//				let srcClass = srcElement.customClass ?? os.controllerType(for: srcElement.name),
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
			// guard let srcClass = srcElement.customClass ?? os.controllerType(for: srcElement.name) else { continue }
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
			guard let segueID = segue.identifier, !segueID.isEmpty else {
				continue
			}

			var navSegue: NavSegue?
			if dstElement.name == "navigationController", let dstController = viewControllers[dstID],
				let segues = dstController.searchNamed(name: "segue")?.map({ Segue(xml: $0, source: scene) }),
				let rootSegue = segues.first(where: { $0.kind == "relationship" && $0.relationshipKind == "rootViewController"}),
				let destination = rootSegue.destination,
				let rootController = viewControllers[destination] {
				guard let segueID = segue.identifier, !segueID.isEmpty else {
					seguePatterns += "\t\t#error(\"no segue id for NavigationSegue from \(srcElement.id ?? srcElement.name), root: \(rootController.storyboardIdentifier  ?? rootController.name )\")"
					continue
				}
				let dstName = swiftRepresentation(for: segueID, firstLetter: .capitalize)
//				} else if let identifier = rootController.storyboardIdentifier {
//					dstName = swiftRepresentation(for: identifier, firstLetter: .capitalize)
//				} else if let customClass = rootController.customClass {
//					dstName = swiftRepresentation(for: customClass, firstLetter: .capitalize)
//				} else {
//					dstName = swiftRepresentation(for: dstElement.name, firstLetter: .capitalize) + "_" + swiftRepresentation(for: dstID, firstLetter: .capitalize)
//				}

				let rootClass = rootController.customClass ?? "UIViewController"
				let segueName = dstName.first!.lowercased() + dstName.dropFirst()
//				let swiftIdentifier = dstName.first!.lowercased() + dstName.dropFirst()
	//					"(_, \(dstRef), \(dstCast))"
				let customSegueClass = segue.xml.element?.attribute(by: "customClass")?.text ?? "UIStoryboardSegue"
				if nil != segue.xml.element?.attribute(by: "customClass") {
					if let customModule = segue.xml.element?.attribute(by: "customModule")?.text {
						storyboardCustomModules.insert(customModule)
					}
				}
				seguePatterns += "\t\tstatic let \(segueName) = NavigationSegue<\(customSegueClass), \(dstClass), \(rootClass)>(identifier: \"\(segueID)\")"

				navSegue = .init(dstID: dstID, dstController: dstController, rootSegue: rootSegue, rootController: rootController, segueID: segueID, dstName: dstName, rootClass: rootClass, segueName: segueName, customSegueClass: customSegueClass)
			}
			
			let pattern = "(\(segue.identifier.unwrappedString), \(dstStoryboardID.unwrappedString), \(dstClass).self)"
			let dstCast = (dstClass == "UIViewController"||dstClass == "NSViewController") ? "_" : "is \(dstClass).Type"
			let dstCastUnwind = (dstClass == "UIViewController"||dstClass == "NSViewController") ? "_" : "is \(dstClass)"
			// let srcRef = (srcClass == "UIViewController"||srcClass == "NSViewController") ? "_" : "\(srcStoryboardID.unwrappedPattern)"
			let dstRef = (dstClass == "UIViewController"||dstClass == "NSViewController") ? "_" : "\(dstStoryboardID.unwrappedPattern)"
			if let value = patterns[pattern], value > 1 {
				continue
			}
			
			if segue.kind == "relationship" {
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
					if nil == navSegue {
						seguePatterns += "\t\tstatic let \(segueName) = Segue<UIStoryboardSegue, \(dstClass)>(identifier: \"\(segueIdentifier)\")" // , segueKind: .\(segue.kind))"
					}
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
			} else if segue.kind != "embed", segue.kind != "relationship" {
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

						if nil == navSegue {
							seguePatterns += "\t\tstatic let \(segueName) = Segue<\(customSegueClass), \(dstClass)>(identifier: \"\(segueID)\")" // , segueKind: .\(segue.kind))"
						}
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
						if nil == navSegue {
							seguePatterns += "\t\t#error(\"no custom class set for segue \(segueName) to \(dstClass) (\(segueID))\")"
						}
					}
				} else {
					let method = "\(functionName)(_ destination: \(dstClass), sender: Any?, segue: UIStoryboardSegue)"

					if nil == navSegue {
						seguePatterns += "\t\tstatic let \(segueName) = Segue<UIStoryboardSegue, \(dstClass)>(identifier: \"\(segueID)\")" // , segueKind: .\(segue.kind))"
					}
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

				delegateMethods += "\tfunc " + canPerformMethod
				delegateMethods += "\tfunc " + canUnwindMethod

				defaultImplementation += "\tfunc " + canPerformMethod + " { true }"
				defaultImplementation += "\tfunc " + canUnwindMethod + " { true }"

				let unwindFunctionName = "unwind" + dstName
				var unwindMethod: String
				if let n = navSegue {
					unwindMethod = "\(unwindFunctionName)(from: \(n.rootClass), to: UIViewController)"
				} else {
					unwindMethod = "\(unwindFunctionName)(from: \(dstClass), to: UIViewController)"
				}
//				let unwindMethod = "\(unwindFunctionName)(from: \(dstClass), to: \(srcClass))"
//				let unwindMethod = "\(unwindFunctionName)(from: UIViewController, to: UIViewController)"
				delegateMethods += "\tfunc " + unwindMethod
				defaultImplementation += "\tfunc " + unwindMethod + " {}"

				unwindMethods += "\t@IBAction func \(unwindFunctionName)(segue: UIStoryboardSegue) {"
				if let n = navSegue {
//				if dstCastUnwind != "_" {
					unwindMethods += n.rootClass == "UIViewController" ?
						"\t\tlet source = segue.source" :
						"\t\tguard let source = segue.source as? \(n.rootClass) else { return }"
				} else {
					unwindMethods += dstClass == "UIViewController" ?
						"\t\tlet source = segue.source" :
						"\t\tguard let source = segue.source as? \(dstClass) else { return }"
//					unwindMethods += "\t\tlet source = segue.source"
				}
//				unwindMethods += "\t\tlet source = segue.source"

//				if srcCastUnwind != "_" {
//					unwindMethods += "\t\tguard let destination = segue.destination as? \(srcClass) else { return }"
//				} else {
//					unwindMethods += "\t\tlet destination = segue.destination"
//				}
				unwindMethods += "\t\tlet destination = segue.destination"
				
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
					if nil == navSegue {
						seguePatterns += "\t\tstatic let \(segueName) = Segue<UIStoryboardSegue, \(dstClass)>(identifier: \"\(segueIdentifier)\")" // , segueKind: .\(segue.kind))"
					}
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
					if nil == navSegue {
						seguePatterns += "\t\tstatic let \(segueName) = Segue<UIStoryboardSegue, \(dstClass)>(identifier: \"\(segueIdentifier)\")" // , segueKind: .\(segue.kind))"
					}
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

		if numberOfCases == 0 && seguePatterns.isEmpty {
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
					declarations += "\t\tstatic let \(reusableIdentifier) = Reusable<\(customClass)>(header: \"\(identifier)\")"
				} else if reusable.key == "sectionFooterView" {
					declarations += "\t\tstatic let \(reusableIdentifier) = Reusable<\(customClass)>(footer: \"\(identifier)\")"
				} else {
					declarations += "\t\tstatic let \(reusableIdentifier) = Reusable<\(customClass)>(\"\(identifier)\", elementKind: reusable.key)"
				}
			} else {
				declarations += "\t\tstatic let \(reusableIdentifier) = Reusable<\(customClass)>(\"\(identifier)\")" // , kind: .\(reusable.kind))"
			}
			allCases.append((reusable.kind, reusableIdentifier, reusable.key))
		}
		return (declarations: declarations, cases: allCases)
	}
	func processReusableCases(_ cases: [(String, String, String)]) -> [String] {
		var output = [String]()
		let table = Dictionary(grouping: cases) { $0.0 }
		output.append(contentsOf: processCollectionView(values: table))
		output.append(contentsOf: processTableView(values: table))
		return output
	}

	func processCollectionView(values: [String: [(String, String, String)]]) -> [String] {
		var output = [String]()
		output += "\t\t" + "struct Prototypes: CollectionViewPrototypes {"
		output += "\t\t\t" + "static let cells: [ReusableProtocol] = ["
		if let reusables = values["collectionViewCell"] {
			output += "\t\t\t\t" + reusables.map { $0.1 }.joined(separator: ", ")
		}
		output += "\t\t\t" + "]"
		output += "\t\t\t" + "static let reusableViews: [ReusableProtocol] = ["
		if let reusables = values["collectionReusableView"] {
			output += "\t\t\t\t" + reusables.map { $0.1 }.joined(separator: ", ")
		}
		output += "\t\t\t" + "]"
		output += "\t\t\t" + "let cells: [String: UICollectionViewCell]"
		output += "\t\t\t" + "let reusableViews: [String: UICollectionReusableView]"
		output += ""
		output += "\t\t\t" + "@_transparent"
		output += "\t\t\t" + "init(collectionView: UICollectionView) {"
		output += "\t\t\t\t" + "let prototypes = Self.makePrototypes(collectionView)"
		output += "\t\t\t\t" + "self.cells = prototypes.0"
		output += "\t\t\t\t" + "self.reusableViews = prototypes.1"
		output += "\t\t\t" + "}"
		output += "\t\t" + "}"
		output += "\t\t" + "static func callAsFunction(_ collectionView: UICollectionView) -> Prototypes {"
		output += "\t\t\t" + ".init(collectionView: collectionView)"
		output += "\t\t" + "}"
		return output
	}
	func processTableView(values: [String: [(String, String, String)]]) -> [String] {
		var output = [String]()
		output += "\t\t" + "struct TablePrototypes: TableViewPrototypes {"
		output += "\t\t\t" + "static let cells: [ReusableProtocol] = ["
		if let reusables = values["tableViewCell"] {
			output += "\t\t\t\t" + reusables.map { $0.1 }.joined(separator: ", ")
		}
		output += "\t\t\t" + "]"
		output += "\t\t\t" + "static let reusableViews: [ReusableProtocol] = ["
		if let reusables = values["tableViewHeaderFooterView"] {
			output += "\t\t\t\t" + reusables.map { $0.1 }.joined(separator: ", ")
		}
		output += "\t\t\t" + "]"
		output += "\t\t\t" + "let cells: [String: UITableViewCell]"
		output += "\t\t\t" + "let reusableViews: [String: UITableViewHeaderFooterView]"
		output += ""
		output += "\t\t\t@_transparent"
		output += "\t\t\t" + "init(tableView: UITableView) {"
		output += "\t\t\t\t" + "let prototypes = Self.makePrototypes(tableView)"
		output += "\t\t\t\t" + "self.cells = prototypes.0"
		output += "\t\t\t\t" + "self.reusableViews = prototypes.1"
		output += "\t\t\t}"
		output += "\t\t}"
		output += "\t\t" + "static func callAsFunction(_ tableView: UITableView) -> TablePrototypes {"
		output += "\t\t\t" + ".init(tableView: tableView)"
		output += "\t\t" + "}"
		return output
	}
}
