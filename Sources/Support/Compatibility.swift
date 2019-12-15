#if os(macOS)
import AppKit
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

#if false // canImport(SwiftUI)
import SwiftUI
public typealias _Identifiable = Swift.Identifiable
// public typealias _IdentifiableValue = SwiftUI.Identifiable
public typealias _IdentifierValuePair<ID, Value> = SwiftUI.IdentifierValuePair<ID, Value> where ID: Hashable
#else

// MARK: - _Cancellable
public protocol _Cancellable {
	func cancel()
}

// MARK: - _Identifiable
/// A class of types whose instances hold the value of an entity with stable identity.
public protocol _Identifiable {
    /// A type representing the stable identity of the entity associated with `self`, a unique identifier that can be compared for equality.
    associatedtype ID: Hashable

    /// The stable identity of the entity associated with `self`, a unique identifier that can be compared for equality.
    var id: Self.ID { get }
}

extension _Identifiable where Self: AnyObject {
    /// The stable identity of the entity associated with `self`, a unique identifier that can be compared for equality.
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}

// MARK: - _IdentifiableValue
/// A type that can be compared for identity equality.
public protocol _IdentifiableValue: _Identifiable {
	/// The type of value identified by `id`.
	associatedtype IdentifiedValue = Self

	/// The value identified by `id`.
	///
	/// By default this returns `self`.
	var identifiedValue: Self.IdentifiedValue { get }
}

public extension _IdentifiableValue where Self == Self.IdentifiedValue {
	@inlinable var identifiedValue: Self { self }
}

// MARK: - _IdentifierValuePair
/// An identifier and value that is uniquely identified by it.
public struct _IdentifierValuePair<ID, Value>: _Identifiable where ID: Hashable {
	/// The type of value identified by `id`.
	public typealias IdentifiedValue = Value

	/// A unique identifier that can be compared for equality.
	public let id: ID
	/// A value identified by `id`.
	public let value: Value

	/// The value identified by `id`.
	///
	/// By default this returns `self`.
	@inlinable public var identifiedValue: Value { value }
}

// MARK: - ProjectionTransform
public struct _ProjectionTransform: Equatable {
	public static let zero = Self(CATransform3DIdentity)

	public var m11: CGFloat
	public var m12: CGFloat
	public var m13: CGFloat
	public var m21: CGFloat
	public var m22: CGFloat
	public var m23: CGFloat
	public var m31: CGFloat
	public var m32: CGFloat
	public var m33: CGFloat

	@inlinable public var isIdentity: Bool { false }
	@inlinable public var isAffine: Bool { false }

	@inlinable
	public init() {
		m11 = 0; m12 = 0; m13 = 0
		m21 = 0; m22 = 0; m23 = 0
		m31 = 0; m32 = 0; m33 = 0
	}
	@inlinable
	public init(_ m: CGAffineTransform) {
		m11 = m.a; m12 = m.b; m13 = 0
		m21 = m.c; m22 = m.d; m23 = 0
		m31 = m.tx; m32 = m.ty; m33 = 0
	}
	@inlinable
	public init(_ m: CATransform3D) {
		m11 = m.m11; m12 = m.m12; m13 = m.m13
		m21 = m.m21; m22 = m.m22; m23 = m.m23
		m31 = m.m31; m32 = m.m32; m33 = m.m33
	}
	@inlinable
	public init(m11: CGFloat, m12: CGFloat, m13: CGFloat,
		m21: CGFloat, m22: CGFloat, m23: CGFloat,
		m31: CGFloat, m32: CGFloat, m33: CGFloat) {
		self.m11 = m11
		self.m12 = m12
		self.m13 = m13
		self.m21 = m21
		self.m22 = m22
		self.m23 = m23
		self.m31 = m31
		self.m32 = m32
		self.m33 = m33
	}

	@available(*, unavailable, message: "Not implemented")
	public mutating func invert() -> Bool {
		false
	}
	
	@available(*, unavailable, message: "Not implemented")
	public func inverted() -> Self {
		.zero
	}

	@inlinable
	public func concatenating(_ other: Self) -> Self {
		self
	}
}
public typealias CGProjectionTransform = _ProjectionTransform
#endif
