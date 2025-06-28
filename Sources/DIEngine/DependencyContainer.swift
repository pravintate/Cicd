//
//  Resolver.swift
//  DIApp
//
//  Created by Pravin Tate on 18/06/25.
//
import Foundation
public enum PropertyObjectScope {
    case new, shared
}
public protocol DependencyContainer {
    func register<Service>(_ serviceType: Service.Type,
                           name: String?,
                           scope: PropertyObjectScope,
                           implementation: @escaping () -> Service)
    func resolve<Service>(_ serviceType: Service.Type,
                          name: String?,
                          scope: PropertyObjectScope) -> Service?
    func cleanAllDependencies(ignoreSingleton: Bool)
    func cleanDependencieServices<Service>(_ serviceTypes: [Service.Type], name: String?)
}
private struct RegistrationKey: Hashable {
    let type: ObjectIdentifier
    let name: String?
}
/**
 DependencyContainerImpl is a concrete implementation of the DependencyContainer protocol.

 This class manages registrations and resolutions of dependencies
 for both singleton (shared) and transient (new) scopes.

 - Thread Safety: This class is **NOT** thread-safe.
 It is designed to be used exclusively through a thread-safe
 wrapper (such as the `Resolver` class), which must synchronize
 all access to this container. Do not access this class directly
 from multiple threads without external synchronization.

 - Usage: Register and resolve services by type and scope.
 Supports cleaning all or specific dependencies.
 */
public final class DependencyContainerImpl: DependencyContainer {
    /// Stores factory closures for transient (new) scope dependencies.
    private var registrations: [RegistrationKey: () -> Any] = [:]
    /// Stores instances for singleton (shared) scope dependencies.
    private var sharedInstances: [RegistrationKey: Any] = [:]

    /**
     Registers a service type with the container.
     - Parameters:
     - serviceType: The type of the service to register.
     - scope: The scope of the registration (.shared for singleton, .
     new for transient). Default is .new.
     - implementation: A closure that returns an instance of the service.
     - Note: Registering the same type with both scopes is allowed and does not overwrite the other.
     */
    public func register<Service>(_ serviceType: Service.Type,
                                  name: String? = nil,
                                  scope: PropertyObjectScope = .new,
                                  implementation: @escaping () -> Service) {
        let registrationKey = RegistrationKey(type: ObjectIdentifier(serviceType), name: name)
        switch scope {
        case .shared:
            sharedInstances[registrationKey] = implementation()
        case .new:
            registrations[registrationKey] = implementation
        }
    }

    /**
     Resolves a registered service type from the container.
     - Parameters:
     - serviceType: The type of the service to resolve.
     - scope: The scope to resolve from (.shared for singleton,
     .new for transient). Default is .new.
     - Returns: An instance of the requested service, or nil if not registered for the specified scope.
     */
    public func resolve<Service>(_ serviceType: Service.Type,
                                 name: String? = nil,
                                 scope: PropertyObjectScope = .new) -> Service? {
        let registrationKey = RegistrationKey(type: ObjectIdentifier(serviceType), name: name)

        if scope == .shared {
            if let sharedInstance = sharedInstances[registrationKey] as? Service {
                return sharedInstance
            }
        } else if let implementationBlock = registrations[registrationKey],
                  let normalObject = implementationBlock() as? Service {
            return normalObject
        }
        return nil
    }

    /**
     Removes all registered dependencies from the container.
     - Parameter ignoreSingleton: If false, also removes all
     shared (singleton) instances. If true, only removes transient registrations.
     */
    public func cleanAllDependencies(ignoreSingleton: Bool) {
        registrations.removeAll()
        if !ignoreSingleton {
            sharedInstances.removeAll()
        }
    }

    /**
     Removes specific registered dependencies from the container for both scopes.
     - Parameter serviceTypes: An array of service types to remove.
     */
    public func cleanDependencieServices<Service>(_ serviceTypes: [Service.Type],
                                                  name: String? = nil) {
        for serviceType in serviceTypes {
            let registrationKey = RegistrationKey(type: ObjectIdentifier(serviceType), name: name)
            registrations[registrationKey] = nil
            sharedInstances[registrationKey] = nil
        }
    }
}
