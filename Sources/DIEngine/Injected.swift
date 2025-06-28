//
//  Injected.swift
//  DIApp
//
//  Created by Pravin Tate on 18/06/25.
//
import Foundation

/**
 Property wrapper for dependency injection using Resolver.

 Usage:
   @Injected var foo: FooProtocol
   @Injected(name: "bar") var bar: FooProtocol

 - Parameters:
   - name: The registration name for the dependency (optional).
   - scope: The object scope (.new or .shared, default: .new).
   - resolver: The Resolver instance to use (default: Resolver.default).
*/
@propertyWrapper
public struct Injected<Service> {
    public var wrappedValue: Service

    public init(name: String? = nil,
                scope: PropertyObjectScope = .new,
                resolver: Resolver = Resolver.default) {
        guard let object = resolver.resolve(Service.self,
                                            name: name,
                                            scope: scope) else {
            let message = """
\(Service.self) is not registered for name '\(name ?? "nil")'
and attempted to inject it.
"""
            fatalError(message)
        }
        self.wrappedValue = object
    }
}
