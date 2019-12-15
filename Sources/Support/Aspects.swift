//
//  Aspects.swift
//  Aspects
//
//  Created by Robert Geifman on 14/12/2019.
//  Copyright © 2019 Peter Steinberger. All rights reserved.
//

import Foundation
import Aspects

public extension NSObject {
	typealias ReplacementBlock = @convention(block) (AspectInfo) -> Void
}

public extension NSObject {
    @nonobjc final func hook(before selector: Selector!,     	body: @escaping ReplacementBlock) throws -> AspectToken {
		try hook(selector, options: .positionBefore, body: body)
	}

    @nonobjc final func hook(after selector: Selector!, body: @escaping ReplacementBlock) throws -> AspectToken  {
	   try hook(selector, options: [], body: body)
   }

    @nonobjc final func hook(instead selector: Selector!, body: @escaping ReplacementBlock) throws -> AspectToken  {
	   try hook(selector, options: .positionInstead, body: body)
   }

	 @nonobjc final func hookOnce(before selector: Selector!, body: @escaping ReplacementBlock) throws -> AspectToken {
		try hook(selector, options: [.optionAutomaticRemoval, .positionBefore], body: body)
	 }

	 @nonobjc final func hookOnce(after selector: Selector!, body: @escaping ReplacementBlock) throws -> AspectToken  {
		try hook(selector, options: [.optionAutomaticRemoval], body: body)
	}

	 @nonobjc final func hookOnce(instead selector: Selector!, body: @escaping ReplacementBlock) throws -> AspectToken  {
		try hook(selector, options: [.optionAutomaticRemoval, .positionInstead], body: body)
	}

	@nonobjc final func hook(_ selector: Selector, options: AspectOptions, body: @escaping ReplacementBlock) throws -> AspectToken {
		try aspect_hook(selector, with: options, usingBlock: unsafeBitCast(body, to: NSObject.self))
	}
}

public extension NSObject {
/*
    @nonobjc final class func hook(before selector: Selector!, removeAutomatically: Bool = false,
    	body: @escaping ReplacementBlock) throws -> AspectToken {
    	if removeAutomatically {
			return try hook(selector, options: [.optionAutomaticRemoval, .positionBefore], body: body)
    	}
		return try hook(selector, options: .positionBefore, body: body)
    }

    @nonobjc final class func hook(after selector: Selector!, removeAutomatically: Bool = false,
    	body: @escaping ReplacementBlock) throws -> AspectToken {
    	if removeAutomatically {
			return try hook(selector, options: [.optionAutomaticRemoval], body: body)
    	}
		return try hook(selector, options: [], body: body)
    }

    @nonobjc final class func hook(instead selector: Selector!, removeAutomatically: Bool = false,
    	body: @escaping ReplacementBlock) throws -> AspectToken {
    	if removeAutomatically {
			return try hook(selector, options: [.optionAutomaticRemoval, .positionInstead], body: body)
    	}
		return try hook(selector, options: .positionInstead, body: body)
    }
*/
}
