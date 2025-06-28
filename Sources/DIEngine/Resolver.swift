//
//  DependencyContainer.swift
//  DIApp
//
//  Created by Pravin Tate on 18/06/25.
//
import Foundation

public protocol ResolverInterface: DependencyContainer {
    func setContainer(_ container: DependencyContainer)
    func reset()
}

public final class Resolver: ResolverInterface, @unchecked Sendable {
    public static let `default` = Resolver()
    private var container: DependencyContainer = DependencyContainerImpl()
    private let lock = NSLock()
    private var customObjects: [String: Resolver] = [:]
    // Private to enforce singleton in production, but see DEBUG extension below for testability.
    private init() {}

    // MARK: - DependencyContainer Protocol Conformance
    public func register<Service>(_ serviceType: Service.Type,
                                  name: String? = nil,
                                  scope: PropertyObjectScope = .new,
                                  implementation: @escaping () -> Service) {
        lock.lock()
        container.register(serviceType, name: name, scope: scope, implementation: implementation)
        lock.unlock()
    }

    public func resolve<Service>(_ serviceType: Service.Type,
                                 name: String? = nil,
                                 scope: PropertyObjectScope = .new) -> Service? {
        lock.lock()
        defer { lock.unlock() }
        return container.resolve(serviceType, name: name, scope: scope)
    }

    public func cleanDependencieServices<Service>(_ serviceTypes: [Service.Type],
                                                  name: String? = nil) {
        lock.lock()
        container.cleanDependencieServices(serviceTypes, name: name)
        lock.unlock()
    }

    // Additional convenience methods
    public func cleanAllDependencies(ignoreSingleton: Bool = true) {
        lock.lock()
        container.cleanAllDependencies(ignoreSingleton: ignoreSingleton)
        lock.unlock()
    }

    public func setContainer(_ container: DependencyContainer) {
        lock.lock()
        self.container = container
        lock.unlock()
    }

    /// Resets the resolver's internal container to a fresh state. Useful for test isolation.
    public func reset() {
        lock.lock()
        self.container = DependencyContainerImpl()
        lock.unlock()
    }
}

#if DEBUG
extension Resolver {
    /// Internal initializer for test support only. Allows creation of non-singleton Resolver in tests.
    convenience init(forTesting: Bool) {
        self.init()
    }
}
#endif
