//
//  Storyboard+Natalie.swift
//  Natalie
//
//  Created by Eric Marchand on 06/06/2017.
//  Copyright © 2017 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

extension Storyboard {
	func processViewControllers(storyboardCustomModules: Set<String>) -> String {
		var output = String()

		for scene in self.scenes {
			if let viewController = scene.viewController {
				if let customClass = viewController.customClass {
					output += "\n"
					output += "// MARK: - \(customClass)\n"

					if let storyboardIdentifier = viewController.storyboardIdentifier {
						output += "protocol \(customClass)IdentifiableProtocol: IdentifiableProtocol { }\n"
						output += "\n"
						output += "extension \(customClass): \(customClass)IdentifiableProtocol { }\n"
						output += "\n"
						output += "extension IdentifiableProtocol where Self: \(customClass) {\n"

						let initIdentifierString = initIdentifier(for: os.storyboardSceneIdentifierType, value: storyboardIdentifier)

						var isCurrentModule = false
						if let customModule = viewController.customModule {
							isCurrentModule = !storyboardCustomModules.contains(customModule)
						}

						if isCurrentModule {
							// Accessors for view controllers defined in the current module should be "internal".
							output += "\tvar storyboardIdentifier: \(os.storyboardSceneIdentifierType)? { return \(initIdentifierString) }\n"
						} else {
							// Accessors for view controllers in external modules (whether system or custom frameworks), should be marked public.
							output += "\tpublic var storyboardIdentifier: \(os.storyboardSceneIdentifierType)? { return \(initIdentifierString) }\n"
						}
						output += "\tstatic var storyboardIdentifier: \(os.storyboardSceneIdentifierType)? { return \(initIdentifierString) }\n"
						output += "}\n"
					}

					if let segues = scene.segues, !segues.isEmpty {
						output += "extension \(os.storyboardSegueType) {\n"
						output += "\tfunc selection() -> \(customClass).Segue? {\n"
						output += "\t\tif let identifier = self.identifier {\n"
						output += "\t\t\treturn \(customClass).Segue(rawValue: identifier)\n"
						output += "\t\t}\n"
						output += "\t\treturn nil\n"
						output += "\t}\n"
						output += "}\n"
						output += "\n"
						output += "extension \(customClass) {\n"
						output += "\tenum Segue {" // : \(os.storyboardSegueIdentifierType), CustomStringConvertible, SegueProtocol {\n"
						for segue in segues {
							if let identifier = segue.identifier,
								let destination = segue.destination,
								let destinationElement = searchById(id: destination)?.element {
									if let destinationClass = (destinationElement.attribute(by: "customClass")?.text ?? os.controllerType(for: destinationElement.name)) {
										let swiftIdentifier = swiftRepresentation(for: identifier, firstLetter: .lowercase)
										output += "\n\t\t\tstatic var \(swiftIdentifier): Segue<\(destinationClass)> { return .init(\"\(identifier)\", \"\(segue.kind)\") } // \(destinationElement.name)"
									} else {
										let swiftIdentifier = swiftRepresentation(for: segue.id, firstLetter: .capitalize)
										output += "\n\t\t\tstatic var \(segue.kind)\(swiftIdentifier): Segue { return .init(\"\(segue.id)\", \"\(segue.kind)\") } // \(destinationElement.name)"
									}
								} else {
									let swiftIdentifier = swiftRepresentation(for: segue.id, firstLetter: .capitalize)
									output += "\n\t\t\tstatic var \(segue.kind)\(swiftIdentifier): Segue { return .init(\"\(segue.id)\", \"\(segue.kind)\") }"
								}
							}

						output += "\n\t}\n"
					}

					if let reusables = viewController.reusables(os) { // ?.filter({ return $0.reuseIdentifier != nil }) //, !reusables.isEmpty {
						output += "\n\tenum Reusable {"
						for reusable in reusables {
							if let identifier = reusable.reuseIdentifier {
								if let customClass = reusable.customClass {
									output += "\n\t\tstatic var \(swiftRepresentation(for: identifier, doNotShadow: reusable.customClass)): Reusable<\(customClass)> { return .init(\"\(identifier)\", \"\(reusable.kind)\") }"
								} else {
									output += "\n\t\tstatic var \(swiftRepresentation(for: identifier)): Reusable { return .init(\"\(identifier)\", \"\(reusable.kind)\") }"
								}
							}
						}
						output += "\n\t}"
					}
					output += "\n}\n"
				}
			}
		}

		output += "\n////////////////////////////////////////////////////////////\n"
		output += "enum Segues {" // : \(os.storyboardSegueIdentifierType), CustomStringConvertible, SegueProtocol {\n"
		for scene in self.scenes {
			if let segues = scene.segues, !segues.isEmpty {
				for segue in segues {
					if let identifier = segue.identifier,
						let destination = segue.destination,
						let destinationElement = searchById(id: destination)?.element {
							if let destinationClass = (destinationElement.attribute(by: "customClass")?.text ?? os.controllerType(for: destinationElement.name)) {
								let swiftIdentifier = swiftRepresentation(for: identifier, firstLetter: .lowercase)
								output += "\n\tstatic var \(swiftIdentifier): Segue<\(destinationClass)> { return .init(\"\(identifier)\", \"\(segue.kind)\") } // \(destinationElement.name)"
							} else {
								let swiftIdentifier = swiftRepresentation(for: segue.id, firstLetter: .capitalize)
								output += "\n\tstatic var \(segue.kind)\(swiftIdentifier): Segue { return .init(\"\(segue.id)\", \"\(segue.kind)\") } // \(destinationElement.name)"
							}
						} else {
							let swiftIdentifier = swiftRepresentation(for: segue.id, firstLetter: .capitalize)
							output += "\n\tstatic var \(segue.kind)\(swiftIdentifier): Segue { return .init(\"\(segue.id)\", \"\(segue.kind)\") }"
						}
					}

				output += "\n"
			}
		}
		output += "\n}\n"

		output += "\n////////////////////////////////////////////////////////////\n"
		output += "\nenum Reusables {"
		for scene in self.scenes {
			if let viewController = scene.viewController, nil == viewController.customClass {
				if let reusables = viewController.reusables(os) { // ?.filter({ return $0.reuseIdentifier != nil }) //, !reusables.isEmpty {
					for reusable in reusables {
						if let identifier = reusable.reuseIdentifier {
							if let customClass = reusable.customClass {
								output += "\n\t\tstatic var \(swiftRepresentation(for: identifier, doNotShadow: reusable.customClass)): Reusable<\(customClass)> { return .init(\"\(identifier)\", \"\(reusable.kind)\") }"
							} else {
								let customClass = os.reusableItemsMap[reusable.kind]
								output += "\n\t\tstatic var \(swiftRepresentation(for: identifier)): Reusable<\(customClass!)> { return .init(\"\(identifier)\", \"\(reusable.kind)\") }"
							}
						}
					}
					output += "\n"
				}
			}
		}
		output += "\n}\n"
		return output
	}

	func processStoryboard(storyboardName: String, os: OS) -> String {
		var output = String()

		output += "\tstruct \(storyboardName): Storyboard {\n"
		output += "\t\tstatic let identifier = \(initIdentifier(for: os.storyboardIdentifierType, value: storyboardName))\n"
		if let initialViewControllerClass = self.initialViewControllerClass {
			let cast = (initialViewControllerClass == os.storyboardControllerReturnType ? (os == OS.iOS ? "!" : "") : " as! \(initialViewControllerClass)")
			output += "\n"
			output += "\t\tstatic func instantiateInitial\(os.storyboardControllerSignatureType)() -> \(initialViewControllerClass) {\n"
			output += "\t\t\treturn self.storyboard.instantiateInitial\(os.storyboardControllerSignatureType)()\(cast)\n"
			output += "\t\t}\n"
		}

		for scene in self.scenes {
			if let viewController = scene.viewController, let storyboardIdentifier = viewController.storyboardIdentifier {
				// The returned class could have the same name as the enclosing Storyboard struct,
				// so we must qualify controllerClass with the module name.
				guard let controllerClass = viewController.customClassWithModule ?? os.controllerType(for: viewController.name) else {
					continue
				}

				let cast = (controllerClass == os.storyboardControllerReturnType ? "" : " as! \(controllerClass)")
				output += "\n"
				output += "\t\tstatic func instantiate\(swiftRepresentation(for: storyboardIdentifier, firstLetter: .capitalize))() -> \(controllerClass) {\n"
				output += "\t\t\treturn self.storyboard.instantiate\(os.storyboardControllerSignatureType)(withIdentifier: \(initIdentifier(for: os.storyboardSceneIdentifierType, value: storyboardIdentifier)))\(cast)\n"
				output += "\t\t}\n"
			}
		}
		output += "\t}\n"
		output += "\n"

		return output
	}
}
