//
//  RuntimeErrors.swift
//  Interpolatable
//
//  Created by Robert Geifman on 02/07/2019.
//  Copyright © 2019 Robert Geifman. All rights reserved.
//

#if os(OSX)
import AppKit
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

// MARK: - preconditionFailure
func preconditionFailure(_ hintExpression: @autoclosure () -> String? = nil, in object: Any, file: StaticString = #file, line: UInt = #line) -> Never {
	let message = hintExpression() ?? "Error: \(type(of: object))"
	preconditionFailure(message + " in \(file), at line \(line)")
}

// MARK: - requireConcreteImplementation
public func requireConcreteImplementation(_ message: @autoclosure () -> String? = nil, in object: Any,
	function: StaticString = #function, file: StaticString = #file, line: UInt = #line) -> Never {
	preconditionFailure(message() ?? "\(type(of: object)) must override function \(function)")
}

public func requireConcreteImplementation<T>(_ message: @autoclosure () -> String? = nil, for type: T.Type,
	function: StaticString = #function, file: StaticString = #file, line: UInt = #line) -> Never {
	preconditionFailure(message() ?? "\(type) must override function \(function)")
}

// MARK: - runtimeError
public func runtimeError(_ message: @autoclosure () -> String? = nil, in object: Any? = nil,
	function: StaticString = #function, file: StaticString = #file, line: UInt = #line) -> Never {
	if let object = object {
		preconditionFailure(message() ?? "runtime error" + "in \(type(of: object)), function \(function), \(file): \(line)")
	}
	preconditionFailure(message() ?? "runtime error" + "in function \(function), \(file): \(line)")
}

public func runtimeError<T>(_ propertyName: String, newValue: T, in object: Any? = nil,
	function: StaticString = #function, file: StaticString = #file, line: UInt = #line) -> Never {
	if let object = object {
		preconditionFailure("runtime error in \(type(of: object)).\(propertyName).setter, \(file): \(line)")
	}
	preconditionFailure("runtime error \(propertyName).setter, \(file): \(line)")
}

public func runtimeError(_ error: Error, in object: Any? = nil,
	function: StaticString = #function, file: StaticString = #file, line: UInt = #line) -> Never {
	if let object = object {
		preconditionFailure("\(error) in \(type(of: object)), function \(function), \(file): \(line)")
	}
	preconditionFailure("\(error) in function \(function), \(file): \(line)")
}
