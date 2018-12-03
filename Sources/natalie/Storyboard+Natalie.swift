//
//  Storyboard+Natalie.swift
//  Natalie
//
//  Created by Eric Marchand on 06/06/2017.
//  Copyright © 2017 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

extension Storyboard {
	func processViewControllers(storyboardCustomModules: Set<String>) -> [String] {
		var output = [String]()
		for scene in self.scenes {
			if let viewController = scene.viewController {
				if let customClass = viewController.customClass {
					output += ""
					output += "// MARK: - \(customClass)"

					if let storyboardIdentifier = viewController.storyboardIdentifier {
						output += "protocol \(customClass)IdentifiableProtocol: IdentifiableProtocol { }"
						output += ""
						output += "extension \(customClass): \(customClass)IdentifiableProtocol { }"
						output += ""
						output += "extension IdentifiableProtocol where Self: \(customClass) {"

						let initIdentifierString = initIdentifier(for: os.storyboardSceneIdentifierType, value: storyboardIdentifier)

						var isCurrentModule = false
						if let customModule = viewController.customModule {
							isCurrentModule = !storyboardCustomModules.contains(customModule)
						}

						if isCurrentModule {
							// Accessors for view controllers defined in the current module should be "internal".
							output += "\tvar storyboardIdentifier: \(os.storyboardSceneIdentifierType)? { return \(initIdentifierString) }"
						} else {
							// Accessors for view controllers in external modules (whether system or custom frameworks), should be marked public.
							output += "\tpublic var storyboardIdentifier: \(os.storyboardSceneIdentifierType)? { return \(initIdentifierString) }"
						}
						output += "\tstatic var storyboardIdentifier: \(os.storyboardSceneIdentifierType)? { return \(initIdentifierString) }"
						output += "}"
						output += ""
					}

#if false
					output += "extension \(os.storyboardSegueType) {"
					output += "\tfunc selection() -> \(customClass).Segue? {"
					output += "\t\tif let identifier = self.identifier {"
					output += "\t\t\treturn \(customClass).Segue(rawValue: identifier)"
					output += "\t\t}"
					output += "\t\treturn nil"
					output += "\t}"
					output += "}"
					output += ""
#endif
					let sceneReusables = viewController.reusables(os)
					let sceneSegues = scene.segues

					var seguesController = [String]()
					var prepareForSegue = [String]()
					let segues = processSegues(sceneSegues, customClass, &seguesController, &prepareForSegue)
					let reusables = processReusables(sceneReusables)

					if !segues.isEmpty || !reusables.isEmpty {
						output += seguesController
						output += ""
						output += "extension \(customClass) {"

						if !segues.isEmpty {
							output += "\tenum Segues: String {" // \(os.storyboardSegueIdentifierType), CustomStringConvertible {" //, SegueProtocol {"
							output += segues
							output += "\t}"
							output += ""
						}

						if !reusables.isEmpty { // ?.filter({ return $0.reuseIdentifier != nil })
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
				}
			}
		}
		return output
	}

	func processStoryboard(storyboardName: String, os: OS) -> [String] {
		var output = [String]()

		output += "\tstruct \(storyboardName): Storyboard {"
		output += "\t\tstatic let identifier = \(initIdentifier(for: os.storyboardIdentifierType, value: storyboardName))"
		output += ""

		let segues = processSegues()
		let reusables = processReusables()
		if !segues.isEmpty {
			output += "\t\tenum Segues: String {"
			output += segues
			output += "\t\t}"
			output += ""
		}

		if !reusables.isEmpty {
			output += "\t\tenum Reusables {"
			output += reusables
			output += "\t\t}"
			output += ""
		}

		if let initialViewControllerClass = self.initialViewControllerClass {
			let cast = (initialViewControllerClass == os.storyboardControllerReturnType ? (os == OS.iOS ? "!" : "") : " as! \(initialViewControllerClass)")
			output += "\t\tstatic func instantiateInitial\(os.storyboardControllerSignatureType)() -> \(initialViewControllerClass) {"
			output += "\t\t\treturn self.storyboard.instantiateInitial\(os.storyboardControllerSignatureType)()\(cast)"
			output += "\t\t}"
			output += ""
		}

		output += processScenes()
		output += "\t}"
		output += ""

		return output
	}

	func processSegues() -> [String] {
		var output = [String]()
		var output2 = [String]()
		output2 += "\t\t\tvar segue: Segue {"
		output2 += "\t\t\t\tswitch self {"

		for scene in self.scenes {
		if let segues = scene.segues, !segues.isEmpty {
			for segue in segues {
				if let identifier = segue.identifier,
					let destination = segue.destination,
					let destinationElement = searchById(id: destination)?.element {
						if let destinationClass = (destinationElement.attribute(by: "customClass")?.text ?? os.controllerType(for: destinationElement.name)) {
							let swiftIdentifier = swiftRepresentation(for: identifier, firstLetter: .lowercase)
//							output += "\t\t\tstatic var \(swiftIdentifier): Segue<\(destinationClass)> { return .init(\"\(identifier)\", \"\(segue.kind)\") }"
							output += "\t\t\tcase \(swiftIdentifier) = \"\(identifier)\""
							output2 += "\t\t\t\tcase .\(swiftIdentifier): return Segue(\"\(identifier)\", \"\(segue.kind)\", \(destinationClass).self)"
						} else {
							let swiftIdentifier = segue.kind + swiftRepresentation(for: segue.id, firstLetter: .capitalize)
							// \(destinationElement.name)
//							output += "\t\t\tstatic var \(segue.kind)\(swiftIdentifier): Segue<\(os.defaultSegueDestinationType)> { return .init(\"\(segue.id)\", \"\(segue.kind)\") }"
							output += "\t\t\tcase \(swiftIdentifier) = \"\(segue.id)\""
							output2 += "\t\t\t\tcase .\(swiftIdentifier): return Segue(\"\(segue.id)\", \"\(segue.kind)\", \(os.defaultSegueDestinationType).self)"
						}
					} else {
						let swiftIdentifier = segue.kind + swiftRepresentation(for: segue.id, firstLetter: .capitalize)
//						output += "\t\t\tstatic var \(segue.kind)\(swiftIdentifier): Segue<\(os.defaultSegueDestinationType)> { return .init(\"\(segue.id)\", \"\(segue.kind)\") }"
						output += "\t\t\tcase \(swiftIdentifier) = \"\(segue.id)\""
						output2 += "\t\t\t\tcase .\(swiftIdentifier): return Segue(\"\(segue.id)\", \"\(segue.kind)\", \(os.defaultSegueDestinationType).self)"
					}
			}
		}
		}

		output2 += "\t\t\t\t}"
		output2 += "\t\t\t}"
		if output.isEmpty {
			return [String]()
		}

		output += output2
		return output
	}

	func processSegues(_ sceneSegues: [Segue]?, _ customClass: String, _ seguesController: inout [String], _ prepareForSegue: inout [String]) -> [String] {
		var output = [String]()
		var output1 = [String]()
		var output2 = [String]()
		var output3 = [String]()
		output1 += "@objc protocol \(customClass)SegueController: NSObjectProtocol {"

		output2 += "\t\tvar segue: Segue {"
		output2 += "\t\t\tswitch self {"

		output3 += "\tinternal var segueController: Any? { return self }"
		output3 += "\toverride func prepare(for segue: NSStoryboardSegue, sender: Any?) {"
		output3 += "\t\tguard let identifier = segue.identifier, "
		output3 += "\t\t\tlet controller = segueController as? \(customClass)SegueController else { super.prepare(for: segue, sender: sender); return }"
		output3 += "\t\tswitch identifier {"
		if let segues = sceneSegues, !segues.isEmpty {
			for segue in segues {
				if let identifier = segue.identifier,
					let destination = segue.destination,
					let destinationElement = searchById(id: destination)?.element {
						if let destinationClass = (destinationElement.attribute(by: "customClass")?.text ?? os.controllerType(for: destinationElement.name)) {
							let swiftIdentifier = swiftRepresentation(for: identifier, firstLetter: .lowercase)
//							output += "\t\tstatic var \(swiftIdentifier): Segue<\(destinationClass)> { return .init(\"\(identifier)\", \"\(segue.kind)\") }"
							output += "\t\tcase \(swiftIdentifier) = \"\(identifier)\""
							output2 += "\t\t\tcase .\(swiftIdentifier): return Segue(\"\(identifier)\", \"\(segue.kind)\", \(destinationClass).self)"
							let functionName = "prepareFor" + swiftRepresentation(for: identifier, firstLetter: .capitalize)
							output1 += "\t@objc optional func \(functionName)(sender: Any?)"
							output3 += "\t\tcase Segues.\(swiftIdentifier).rawValue: controller.\(functionName)?(sender: sender)"
						} else {
							let swiftIdentifier = segue.kind + swiftRepresentation(for: segue.id, firstLetter: .capitalize)
							// \(destinationElement.name)
//							output += "\t\tstatic var \(segue.kind)\(swiftIdentifier): Segue<\(os.defaultSegueDestinationType)> { return .init(\"\(segue.id)\", \"\(segue.kind)\") }"
							output += "\t\tcase \(swiftIdentifier) = \"\(segue.id)\""
							output2 += "\t\t\tcase .\(swiftIdentifier): return Segue(\"\(segue.id)\", \"\(segue.kind)\", \(os.defaultSegueDestinationType).self)"
							let functionName = "prepareFor" + swiftRepresentation(for: segue.kind, firstLetter: .capitalize) + swiftRepresentation(for: segue.id, firstLetter: .capitalize)
							output1 += "\t@objc optional func \(functionName)(sender: Any?)"
							output3 += "\t\tcase Segues.\(swiftIdentifier).rawValue: controller.\(functionName)?(sender: sender)"
						}
					} else {
						let swiftIdentifier = segue.kind + swiftRepresentation(for: segue.id, firstLetter: .capitalize)
//						output += "\t\tstatic var \(segue.kind)\(swiftIdentifier): Segue<\(os.defaultSegueDestinationType)> { return .init(\"\(segue.id)\", \"\(segue.kind)\") }"
						output += "\t\tcase \(swiftIdentifier) = \"\(segue.id)\""
						output2 += "\t\t\tcase .\(swiftIdentifier): return Segue(\"\(segue.id)\", \"\(segue.kind)\", \(os.defaultSegueDestinationType).self)"
						let functionName = "prepareFor" + swiftRepresentation(for: segue.kind, firstLetter: .capitalize) + swiftRepresentation(for: segue.id, firstLetter: .capitalize)
						output1 += "\t@objc optional func \(functionName)(sender: Any?)"
						output3 += "\t\tcase Segues.\(swiftIdentifier).rawValue: controller.\(functionName)?(sender: sender)"
					}
			}
		}

		output1 += "}"

		output2 += "\t\t\t}"
		output2 += "\t\t}"

		output3 += "\t\tdefault: super.prepare(for: segue, sender: sender)"
		output3 += "\t\t}"
		output3 += "\t}"

		if output.isEmpty {
			return [String]()
		}

		output += ""
		output += output2

		seguesController = output1
		prepareForSegue = output3
		return output
	}

	func processReusables() -> [String] {
		var output = [String]()
		for scene in self.scenes {
			if let viewController = scene.viewController, nil == viewController.customClass {
				if let reusables = viewController.reusables(os) { // ?.filter({ return $0.reuseIdentifier != nil }) //, !reusables.isEmpty {
					for reusable in reusables {
						if let identifier = reusable.reuseIdentifier {
							if let customClass = reusable.customClass {
								output += "\t\\ttstatic var \(swiftRepresentation(for: identifier, doNotShadow: reusable.customClass)): Reusable { return .init(\"\(identifier)\", \"\(reusable.kind)\", \(customClass).self) }"
							} else {
								let customClass = os.reusableItemsMap[reusable.kind]
								output += "\t\t\tstatic var \(swiftRepresentation(for: identifier)): Reusable { return .init(\"\(identifier)\", \"\(reusable.kind)\", \(customClass!).self) }"
							}
						}
					}
				}
			}
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

	func processScenes() -> [String] {
		var output = [String]()
		for scene in self.scenes {
			if let viewController = scene.viewController, let storyboardIdentifier = viewController.storyboardIdentifier {
				// The returned class could have the same name as the enclosing Storyboard struct,
				// so we must qualify controllerClass with the module name.
				guard let controllerClass = viewController.customClassWithModule ?? os.controllerType(for: viewController.name) else {
					continue
				}

				let cast = (controllerClass == os.storyboardControllerReturnType ? "" : " as! \(controllerClass)")
				output += "\t\tstatic func instantiate\(swiftRepresentation(for: storyboardIdentifier, firstLetter: .capitalize))() -> \(controllerClass) {"
				output += "\t\t\treturn self.storyboard.instantiate\(os.storyboardControllerSignatureType)(withIdentifier: \(initIdentifier(for: os.storyboardSceneIdentifierType, value: storyboardIdentifier)))\(cast)"
				output += "\t\t}"
				output += ""
			}
		}
		return output
	}
}
