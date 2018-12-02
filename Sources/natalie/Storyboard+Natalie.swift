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

					let segues = processSegues(sceneSegues)
					let reusables = processReusables(sceneReusables)

					if !segues.isEmpty || !reusables.isEmpty {
						output += "extension \(customClass) {"

						if !segues.isEmpty {
							output += "\tenum Segues {" // : \(os.storyboardSegueIdentifierType), CustomStringConvertible, SegueProtocol {"
							output += segues
							output += "\t}"
						}

						if !segues.isEmpty && !reusables.isEmpty {
							output += ""
						}

						if !reusables.isEmpty { // ?.filter({ return $0.reuseIdentifier != nil })
							output += "\tenum Reusables {"
							output += reusables
							output += "\t}"
						}

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
			output += "\t\tenum Segues {"
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
		for scene in self.scenes {
		if let segues = scene.segues, !segues.isEmpty {
			for segue in segues {
				if let identifier = segue.identifier,
					let destination = segue.destination,
					let destinationElement = searchById(id: destination)?.element {
						if let destinationClass = (destinationElement.attribute(by: "customClass")?.text ?? os.controllerType(for: destinationElement.name)) {
							let swiftIdentifier = swiftRepresentation(for: identifier, firstLetter: .lowercase)
							output += "\t\t\tstatic var \(swiftIdentifier): Natalie.Segue<\(destinationClass)> { return .init(\"\(identifier)\", \"\(segue.kind)\") } // \(destinationElement.name)"
						} else {
							let swiftIdentifier = swiftRepresentation(for: segue.id, firstLetter: .capitalize)
							output += "\t\t\tstatic var \(segue.kind)\(swiftIdentifier): Natalie.Segue<\(os.defaultSegueDestinationType)> { return .init(\"\(segue.id)\", \"\(segue.kind)\") } // \(destinationElement.name)"
						}
					} else {
						let swiftIdentifier = swiftRepresentation(for: segue.id, firstLetter: .capitalize)
						output += "\t\t\tstatic var \(segue.kind)\(swiftIdentifier): Natalie.Segue<\(os.defaultSegueDestinationType)> { return .init(\"\(segue.id)\", \"\(segue.kind)\") }"
					}
			}
		}
		}
		return output
	}

	func processSegues(_ sceneSegues: [Segue]?) -> [String] {
		var output = [String]()
		if let segues = sceneSegues, !segues.isEmpty {
			for segue in segues {
				if let identifier = segue.identifier,
					let destination = segue.destination,
					let destinationElement = searchById(id: destination)?.element {
						if let destinationClass = (destinationElement.attribute(by: "customClass")?.text ?? os.controllerType(for: destinationElement.name)) {
							let swiftIdentifier = swiftRepresentation(for: identifier, firstLetter: .lowercase)
							output += "\t\tstatic var \(swiftIdentifier): Natalie.Segue<\(destinationClass)> { return .init(\"\(identifier)\", \"\(segue.kind)\") } // \(destinationElement.name)"
						} else {
							let swiftIdentifier = swiftRepresentation(for: segue.id, firstLetter: .capitalize)
							output += "\t\tstatic var \(segue.kind)\(swiftIdentifier): Natalie.Segue<\(os.defaultSegueDestinationType)> { return .init(\"\(segue.id)\", \"\(segue.kind)\") } // \(destinationElement.name)"
						}
					} else {
						let swiftIdentifier = swiftRepresentation(for: segue.id, firstLetter: .capitalize)
						output += "\t\tstatic var \(segue.kind)\(swiftIdentifier): Natalie.Segue<\(os.defaultSegueDestinationType)> { return .init(\"\(segue.id)\", \"\(segue.kind)\") }"
					}
			}
		}
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
								output += "\t\\ttstatic var \(swiftRepresentation(for: identifier, doNotShadow: reusable.customClass)): Natalie.Reusable<\(customClass)> { return .init(\"\(identifier)\", \"\(reusable.kind)\") }"
							} else {
								let customClass = os.reusableItemsMap[reusable.kind]
								output += "\t\t\tstatic var \(swiftRepresentation(for: identifier)): Natalie.Reusable<\(customClass!)> { return .init(\"\(identifier)\", \"\(reusable.kind)\") }"
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
						output += "\t\tstatic var \(swiftRepresentation(for: identifier, doNotShadow: reusable.customClass)): Natalie.Reusable<\(customClass)> { return .init(\"\(identifier)\", \"\(reusable.kind)\") }"
					} else {
						let customClass = os.reusableItemsMap[reusable.kind]
						output += "\t\tstatic var \(swiftRepresentation(for: identifier)): Natalie.Reusable<\(customClass!)> { return .init(\"\(identifier)\", \"\(reusable.kind)\") }"
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
