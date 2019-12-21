//
//  Storyboard+Natalie.swift
//  Natalie
//
//  Created by Eric Marchand on 06/06/2017.
//  Copyright © 2017 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

extension Storyboard {
	func processStoryboard(storyboardName: String, os: OS) -> [String] {
		var output = [String]()

		let name = swiftRepresentation(for: storyboardName, firstLetter: .capitalize)
		output += "\tstruct \(name): AnyStoryboard {"
		output += "\t\tstatic let identifier = \(initIdentifier(for: os.storyboardIdentifierType, value: storyboardName))"

		if let initialViewControllerClass = self.initialViewControllerClass {
			output += ""
			let cast = (initialViewControllerClass == os.storyboardControllerReturnType ? (os == OS.iOS ? "!" : "") : " as! \(initialViewControllerClass)")
			output += "\t\tstatic func instantiateInitial\(os.storyboardControllerSignatureType)() -> \(initialViewControllerClass) {"
			output += "\t\t\tstoryboard.instantiateInitial\(os.storyboardControllerSignatureType)()\(cast)"
			output += "\t\t}"
		}

		let scenes = processScenes()
		if !scenes.isEmpty {
			output += ""
			output += scenes
		}
		output += "\t}"
		output += ""

		return output
	}

	func processScenes() -> [String] {
		var output = [String]()
		for scene in self.scenes {
			if let viewController = scene.viewController, let storyboardIdentifier = viewController.storyboardIdentifier {
				// The returned class could have the same name as the enclosing Storyboard struct, so we must qualify controllerClass with the module name.
				guard let controllerClass = viewController.customClassWithModule ?? os.controllerType(for: viewController.name) else {
					continue
				}

				let cast = (controllerClass == os.storyboardControllerReturnType ? "" : " as! \(controllerClass)")
				output += "\t\tstatic func instantiate\(swiftRepresentation(for: storyboardIdentifier, firstLetter: .capitalize))() -> \(controllerClass) {"
				output += "\t\t\tstoryboard.instantiate\(os.storyboardControllerSignatureType)(withIdentifier: \(initIdentifier(for: os.storyboardSceneIdentifierType, value: storyboardIdentifier)))\(cast)"
				output += "\t\t}"
			}
		}
		return output
	}

	func processIdentifier(scene: Scene, storyboardCustomModules: Set<String>) -> [String] {
		var output = [String]()
		if let viewController = scene.viewController,
			let customClass = viewController.customClass,
			let storyboardIdentifier = viewController.storyboardIdentifier {
			output += "protocol \(customClass)Scene: AnyScene { }"
			output += ""
			output += "extension \(customClass): \(customClass)Scene { }"
			output += ""
			output += "extension AnyScene where Self: \(customClass) {"

			let initIdentifierString = initIdentifier(for: os.storyboardSceneIdentifierType, value: storyboardIdentifier)

			var isCurrentModule = false
			if let customModule = viewController.customModule {
				isCurrentModule = !storyboardCustomModules.contains(customModule)
			}

			if isCurrentModule {
				// Accessors for view controllers defined in the current module should be "internal".
				output += "\tvar identifier: \(os.storyboardSceneIdentifierType)? { \(initIdentifierString) }"
			} else {
				// Accessors for view controllers in external modules (whether system or custom frameworks), should be marked public.
				output += "\tpublic var identifier: \(os.storyboardSceneIdentifierType)? { \(initIdentifierString) }"
			}
			output += "\tstatic var identifier: \(os.storyboardSceneIdentifierType)? { \(initIdentifierString) }"
			output += "}"
			output += ""
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
		}
		return output
	}
}
