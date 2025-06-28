//
//  DependencyContainerTest.swift
//  DIApp
//
//  Created by Pravin Tate on 18/06/25.
//
import Testing
@testable import DIEngine

private protocol MockProtocol {
    var name: String { get }
    func getMessage() -> String
}

private final class MockClass: MockProtocol {
    var name: String = "Mock"
    func getMessage() -> String {
        return "Hello World"
    }
}

private final class ImplA: MockProtocol {
    var name: String = "A"
    func getMessage() -> String { "A" }
}
private final class ImplB: MockProtocol {
    var name: String = "B"
    func getMessage() -> String { "B" }
}

@Suite("Container testing")
struct DependencyContainerTest {
    @Test("property without register")
    func test1() async throws {
        let container = DependencyContainerImpl()

        if container.resolve(MockProtocol.self) != nil {
            #expect(Bool(false))
        }
    }

    @Test("property with register")
    func test2() async throws {
        let container = DependencyContainerImpl()

        container.register(MockProtocol.self) {
            MockClass()
        }
        guard container.resolve(MockProtocol.self) != nil else {
            #expect(Bool(false))
            return
        }
    }

    @Test("register and resolve multiple implementations by name")
    func testNamedRegistrations() {
        let container = DependencyContainerImpl()
        container.register(MockProtocol.self, name: "A") { ImplA() }
        container.register(MockProtocol.self, name: "B") { ImplB() }
        let aClass = container.resolve(MockProtocol.self, name: "A")
        let bClass = container.resolve(MockProtocol.self, name: "B")
        #expect(aClass?.getMessage() == "A")
        #expect(bClass?.getMessage() == "B")
    }

    @Test("property register multiple times")
    func test3() async throws {
        let container = DependencyContainerImpl()
        let lastObject = MockClass()
        lastObject.name = "latestObject"
        container.register(MockProtocol.self) {
            MockClass()
        }
        container.register(MockProtocol.self) {
            MockClass()
        }
        container.register(MockProtocol.self) {
            MockClass()
        }
        container.register(MockProtocol.self) {
            lastObject
        }
        guard let object = container.resolve(MockProtocol.self) else {
            #expect(Bool(false))
            return
        }
        #expect(object.name == "latestObject")
    }

    @Test("Property register in new scope but trying to get as shared")
    func test4() {
        let container = DependencyContainerImpl()
        container.register(MockProtocol.self) {
            MockClass()
        }
        if container.resolve(MockProtocol.self, scope: .shared) != nil {
            #expect(Bool(false))
        }
        guard container.resolve(MockProtocol.self) != nil else {
            #expect(Bool(false))
            return
        }
    }

    @Test("Property register in shared scope but trying to get as new")
    func test5() {
        let container = DependencyContainerImpl()
        container.register(MockProtocol.self, scope: .shared) {
            MockClass()
        }
        if container.resolve(MockProtocol.self, scope: .new) != nil {
            #expect(Bool(false))
        }
        guard container.resolve(MockProtocol.self, scope: .shared) != nil else {
            #expect(Bool(false))
            return
        }
    }

    @Test("clear all functionality with shared")
    func test6() {
        let container = DependencyContainerImpl()
        container.register(MockProtocol.self, scope: .shared) {
            MockClass()
        }
        container.register(MockProtocol.self) {
            MockClass()
        }
        container.cleanDependencieServices([MockProtocol.self])

        if container.resolve(MockProtocol.self, scope: .new) != nil {
            #expect(Bool(false))
        }
        if container.resolve(MockProtocol.self, scope: .shared) != nil {
            #expect(Bool(false))
        }
    }

    @Test("clean named registration only")
    func testCleanNamedRegistration() {
        let container = DependencyContainerImpl()
        container.register(MockProtocol.self, name: "A") { ImplA() }
        container.register(MockProtocol.self, name: "B") { ImplB() }
        container.cleanDependencieServices([MockProtocol.self], name: "A")
        let aClass = container.resolve(MockProtocol.self, name: "A")
        let bClass = container.resolve(MockProtocol.self, name: "B")
        #expect(aClass == nil)
        #expect(bClass?.getMessage() == "B")
    }

    @Test("clear all except shared")
    func test7() {
        let container = DependencyContainerImpl()
        container.register(MockProtocol.self, scope: .shared) {
            MockClass()
        }
        container.register(MockProtocol.self) {
            MockClass()
        }
        container.cleanAllDependencies(ignoreSingleton: true)
        if container.resolve(MockProtocol.self, scope: .new) != nil {
            #expect(Bool(false))
        }
        guard container.resolve(MockProtocol.self, scope: .shared) != nil else {
            #expect(Bool(false))
            return
        }
    }

    @Test("clear all including shared")
    func test8() {
        let container = DependencyContainerImpl()
        container.register(MockProtocol.self, scope: .shared) {
            MockClass()
        }
        container.register(MockProtocol.self) {
            MockClass()
        }
        container.cleanAllDependencies(ignoreSingleton: false)
        if container.resolve(MockProtocol.self, scope: .new) != nil {
            #expect(Bool(false))
        }
        if container.resolve(MockProtocol.self, scope: .shared) != nil {
            #expect(Bool(false))
        }
    }
}
