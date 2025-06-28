//
//  ResolverTest.swift
//  DIAppTests
//
//  Created by Cascade AI on 24/06/25.
//
import Testing
@testable import DIEngine

private protocol MockProtocol {
    var name: String { get }
    func getMessage() -> String
}

private final class MockClass: MockProtocol {
    var name: String = "Mock"
    func getMessage() -> String { return "Hello World" }
}

private final class ImplA: MockProtocol {
    var name: String = "A"
    func getMessage() -> String { "A" }
}
private final class ImplB: MockProtocol {
    var name: String = "B"
    func getMessage() -> String { "B" }
}

@Suite("Resolver Unit Tests")
struct ResolverTest {
    @Test("register and resolve default (unnamed)")
    func testDefaultRegistration() {
        let resolver = Resolver(forTesting: true)
        resolver.register(MockProtocol.self) { MockClass() }
        let result = resolver.resolve(MockProtocol.self)
        #expect(result?.getMessage() == "Hello World")
    }

    @Test("register and resolve named implementations")
    func testNamedRegistration() {
        let resolver = Resolver(forTesting: true)
        resolver.register(MockProtocol.self, name: "A") { ImplA() }
        resolver.register(MockProtocol.self, name: "B") { ImplB() }
        let aClass = resolver.resolve(MockProtocol.self, name: "A")
        let bClass = resolver.resolve(MockProtocol.self, name: "B")
        #expect(aClass?.getMessage() == "A")
        #expect(bClass?.getMessage() == "B")
    }

    @Test("singleton (shared) scope")
    func testSharedScope() {
        let resolver = Resolver(forTesting: true)
        resolver.register(MockClass.self, scope: .shared) { MockClass() }
        let instance1 = resolver.resolve(MockClass.self, scope: .shared)
        let instance2 = resolver.resolve(MockClass.self, scope: .shared)
        #expect(instance1 === instance2)
    }

    @Test("transient (new) scope")
    func testNewScope() {
        let resolver = Resolver(forTesting: true)
        resolver.register(MockClass.self, scope: .new) { MockClass() }
        let instance1 = resolver.resolve(MockClass.self, scope: .new)
        let instance2 = resolver.resolve(MockClass.self, scope: .new)
        #expect(instance1 !== instance2)
    }

    @Test("reset clears all registrations and shared instances")
    func testReset() {
        let resolver = Resolver(forTesting: true)
        resolver.register(MockClass.self, scope: .shared) { MockClass() }
        resolver.register(MockProtocol.self, name: "A") { ImplA() }
        #expect(resolver.resolve(MockClass.self, scope: .shared) != nil)
        #expect(resolver.resolve(MockProtocol.self, name: "A") != nil)
        resolver.reset()
        #expect(resolver.resolve(MockClass.self, scope: .shared) == nil)
        #expect(resolver.resolve(MockProtocol.self, name: "A") == nil)
    }

    @Test("cleanDependencieServices removes only specified named registration")
    func testCleanNamed() {
        let resolver = Resolver(forTesting: true)
        resolver.register(MockProtocol.self, name: "A") { ImplA() }
        resolver.register(MockProtocol.self, name: "B") { ImplB() }
        resolver.cleanDependencieServices([MockProtocol.self], name: "A")
        #expect(resolver.resolve(MockProtocol.self, name: "A") == nil)
        #expect(resolver.resolve(MockProtocol.self, name: "B") != nil)
    }

    @Test("cleanAllDependencies removes only transient registrations if ignoreSingleton is true")
    func testCleanAllDependenciesTransientOnly() {
        let resolver = Resolver(forTesting: true)
        resolver.register(MockClass.self, scope: .shared) { MockClass() }
        resolver.register(MockClass.self, scope: .new) { MockClass() }
        resolver.cleanAllDependencies(ignoreSingleton: true)
        #expect(resolver.resolve(MockClass.self, scope: .new) == nil)
        #expect(resolver.resolve(MockClass.self, scope: .shared) != nil)
    }

    @Test("cleanAllDependencies removes all if ignoreSingleton is false")
    func testCleanAllDependenciesAll() {
        let resolver = Resolver(forTesting: true)
        resolver.register(MockClass.self, scope: .shared) { MockClass() }
        resolver.register(MockClass.self, scope: .new) { MockClass() }
        resolver.cleanAllDependencies(ignoreSingleton: false)
        #expect(resolver.resolve(MockClass.self, scope: .new) == nil)
        #expect(resolver.resolve(MockClass.self, scope: .shared) == nil)
    }
}
