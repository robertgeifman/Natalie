//
//	Optional.swift
//	Expressionism
//
//	Created by Robert Geifman on 16/07/2017.
//	Copyright © 2017 Robert Geifman. All rights reserved.
//

////////////////////////////////////////////////////////////
public enum OptionalError: Error {
	case unexpectedNil
}

public extension Optional {
    var canUnwrap: Bool {
        return self != nil
	}

    func unwrap() throws->Wrapped {
        guard let value = self else { throw OptionalError.unexpectedNil }
        return value
    }
}
