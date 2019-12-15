//
//  Bindable.swift
//  CrossKit
//
//  Created by Robert Geifman on 07/04/2019.
//  Copyright © 2019 John Sundell. All rights reserved.
//

////////////////////////////////////////////////////////////
final public class Bindable<Value> {
	private var observations = [(Value) -> Bool]()
	private var lastValue: Value?

	public init(_ value: Value? = nil) {
		lastValue = value
	}

	public func bind<O: AnyObject, T>(_ sourceKeyPath: KeyPath<Value, T>,
		to object: O, _ objectKeyPath: ReferenceWritableKeyPath<O, T>) {
		addObservation(for: object) { object, observed in
			let value = observed[keyPath: sourceKeyPath]
			object[keyPath: objectKeyPath] = value
		}
	}

	public func bind<O: AnyObject, T>(_ sourceKeyPath: KeyPath<Value, T>,
		to object: O, _ objectKeyPath: ReferenceWritableKeyPath<O, T?>) {
		addObservation(for: object) { object, observed in
			let value = observed[keyPath: sourceKeyPath]
			object[keyPath: objectKeyPath] = value
		}
	}

	public func bind<O: AnyObject, T, R>(_ sourceKeyPath: KeyPath<Value, T>,
		to object: O, _ objectKeyPath: ReferenceWritableKeyPath<O, R?>,
		transform: @escaping (T) -> R?) {
		addObservation(for: object) { object, observed in
		let value = observed[keyPath: sourceKeyPath]
		let transformed = transform(value)
		object[keyPath: objectKeyPath] = transformed
	}
}

	private func addObservation<O: AnyObject>(for object: O, handler: @escaping (O, Value) -> Void) {
		// If we already have a value available, we'll give the handler access to it directly.
		lastValue.map { handler(object, $0) }

		// Each observation closure returns a Bool that indicates whether the observation should still be kept alive,	 based on whether the observing object is still retained.
		observations.append { [weak object] value in
			guard let object = object else { return false }
			handler(object, value)
			return true
		}
	}

	internal func update(with value: Value) {
		lastValue = value
		observations = observations.filter { $0(value) }
	}
}

#if false
class ProfileViewController: NSViewController {
	private let user: Bindable<User>

	init(user: Bindable<User>) {
		self.user = user
		super.init(nibName: nil, bundle: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		addNameLabel()
		addHeaderView()
		addFollowersLabel()
	}

	func addNameLabel() {
		let label = NSTextField()
		user.bind(\.name, to: label, \.text)
		view.addSubview(label)
	}

	func addHeaderView() {
		let header = NSTextField()
		user.bind(\.colors.primary, to: header, \.backgroundColor)
		view.addSubview(header)
	}

	func addFollowersLabel() {
		let label = NSTextField()
		user.bind(\.followersCount, to: label, \.text, transform: String.init)
		view.addSubview(label)
	}
}

class UserModelController {
	let user: Bindable<User>
	private let syncService: SyncService<User>

	init(user: User, syncService: SyncService<User>) {
		self.user = Bindable(user)
		self.syncService = syncService
	}

	func applicationDidBecomeActive() {
		syncService.sync(then: user.update)
	}
}
#endif

