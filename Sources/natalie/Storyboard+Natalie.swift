//
//  Storyboard+Natalie.swift
//  Natalie
//
//  Created by Eric Marchand on 06/06/2017.
//  Copyright © 2017 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

extension Storyboard {

	func processStoryboard(storyboardName: String, os: OS) -> String {
		var output = String()

		output += "\tstruct \(storyboardName): Storyboard {\n"
		output += "\t\tstatic let identifier = \(initIdentifier(for: os.storyboardIdentifierType, value: storyboardName))\n"
		output += "\n"
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

	func processViewControllers(storyboardCustomModules: Set<String>) -> String {
		var output = String()

		for scene in self.scenes {
			if let viewController = scene.viewController {
				if let customClass = viewController.customClass {
					output += "\n"
					output += "// MARK: - \(customClass)\n"

					if let segues = scene.segues?.filter({ return $0.identifier != nil }), !segues.isEmpty {
						output += "extension \(os.storyboardSegueType) {\n"
						output += "\tfunc selection() -> \(customClass).Segue? {\n"
						output += "\t\tif let identifier = self.identifier {\n"
						output += "\t\t\treturn \(customClass).Segue(rawValue: identifier)\n"
						output += "\t\t}\n"
						output += "\t\treturn nil\n"
						output += "\t}\n"
						output += "}\n"
					}

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

					if let segues = scene.segues?.filter({ return $0.identifier != nil }), !segues.isEmpty {
						output += "extension \(customClass) {\n"
						output += "\tenum Segue: \(os.storyboardSegueIdentifierType), CustomStringConvertible, SegueProtocol {\n"
						for segue in segues {
							if let identifier = segue.identifier {
								let swiftIdentifier = swiftRepresentation(for: identifier, firstLetter: .lowercase)
								if swiftIdentifier == identifier {
									output += "\t\tcase \(swiftIdentifier)\n"
								} else {
									output += "\t\tcase \(swiftIdentifier) = \"\(identifier)\"\n"
								}
							}
						}
						output += "\n"
						output += "\t\tvar kind: SegueKind? {\n"
						output += "\t\t\tswitch self {\n"
						var needDefaultSegue = false
						for segue in segues {
							if let identifier = segue.identifier {
								output += "\t\t\tcase .\(swiftRepresentation(for: identifier, firstLetter: .lowercase)):\n"
								output += "\t\t\t\treturn SegueKind(rawValue: \"\(segue.kind)\")\n"
							} else {
								needDefaultSegue = true
							}
						}
						if needDefaultSegue {
							output += "\t\t\tdefault:\n"
							output += "\t\t\t\tassertionFailure(\"Invalid value\")\n"
							output += "\t\t\t\treturn nil\n"
						}
						output += "\t\t\t}\n"
						output += "\t\t}\n"
						output += "\n"
						output += "\t\tvar destination: \(self.os.storyboardControllerReturnType).Type? {\n"
						output += "\t\t\tswitch self {\n"
						var needDefaultDestination = false
						for segue in segues {
							if let identifier = segue.identifier, let destination = segue.destination,
								let destinationElement = searchById(id: destination)?.element,
								let destinationClass = (destinationElement.attribute(by: "customClass")?.text ?? os.controllerType(for: destinationElement.name)) {
								output += "\t\t\tcase .\(swiftRepresentation(for: identifier, firstLetter: .lowercase)):\n"
								output += "\t\t\t\treturn \(destinationClass).self\n"
							} else {
								needDefaultDestination = true
							}
						}
						if needDefaultDestination {
							output += "\t\t\tdefault:\n"
							output += "\t\t\t\tassertionFailure(\"Unknown destination\")\n"
							output += "\t\t\t\treturn nil\n"
						}
						output += "\t\t\t}\n"
						output += "\t\t}\n"
						output += "\n"
						output += "\t\tvar identifier: \(os.storyboardSegueIdentifierType)? { return self.rawValue }\n"
						output += "\t\tvar description: String { return \"\\(self.rawValue)\" }\n"
						output += "\t}\n"
						output += "\n"
						output += "}\n"
						output += "\n"
					}

					if let reusables = viewController.reusables?.filter({ return $0.reuseIdentifier != nil }), !reusables.isEmpty {
						output += "extension \(customClass) {\n"
						output += "\tenum Reusable: String, CustomStringConvertible, ReusableViewProtocol {\n"
						for reusable in reusables {
							if let identifier = reusable.reuseIdentifier {
								output += "\t\tcase \(swiftRepresentation(for: identifier, doNotShadow: reusable.customClass)) = \"\(identifier)\"\n"
							}
						}
						output += "\n"
						output += "\t\tvar kind: ReusableKind? {\n"
						output += "\t\t\tswitch self {\n"
						var needDefault = false
						for reusable in reusables {
							if let identifier = reusable.reuseIdentifier {
								output += "\t\t\tcase .\(swiftRepresentation(for: identifier, doNotShadow: reusable.customClass)):\n"
								output += "\t\t\t\treturn ReusableKind(rawValue: \"\(reusable.kind)\")\n"
							} else {
								needDefault = true
							}
						}
						if needDefault {
							output += "\t\t\tdefault:\n"
							output += "\t\t\t\tpreconditionFailure(\"Invalid value\")\n"
							output += "\t\t\t\tbreak\n"
						}
						output += "\t\t\t}\n"
						output += "\t\t}\n"
						output += "\n"
						output += "\t\tvar viewType: \(self.os.viewType).Type? {\n"
						output += "\t\t\tswitch self {\n"
						needDefault = false
						for reusable in reusables {
							if let identifier = reusable.reuseIdentifier, let customClass = reusable.customClass {
								output += "\t\t\tcase .\(swiftRepresentation(for: identifier, doNotShadow: reusable.customClass)):\n"
								output += "\t\t\t\treturn \(customClass).self\n"
							} else {
								needDefault = true
							}
						}
						if needDefault {
							output += "\t\t\tdefault:\n"
							output += "\t\t\t\treturn nil\n"
						}
						output += "\t\t\t}\n"
						output += "\t\t}\n"
						output += "\n"
						output += "\t\tvar storyboardIdentifier: String? { return self.description }\n"
						output += "\t\tvar description: String { return self.rawValue }\n"
						output += "\t}\n"
						output += "\n"
						output += "}\n"
						output += "\n"
					}
				}
			}
		}
		return output
	}
}
