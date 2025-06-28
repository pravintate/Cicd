//
//  InjectedTest.swift
//  DIApp
//
//  Created by Pravin Tate on 19/06/25.
//
import Testing
import Foundation
@testable import DIEngine

@Suite("Injected Test")
struct InjectedTest {
    @Test("test with valid registration")
    func test1() {
        Resolver.default.register(MockClass.self) {
            MockClass("default")
        }
        struct TestingDemo {
            @Injected var mockClass: MockClass
        }
        #expect(TestingDemo().mockClass.getGreetings("World") == "Hello default World")
    }

    @Test("property wrapper injects correct named implementation")
    func testInjectedNamed() {
        Resolver.default.register(MockClass.self, name: "A") { MockClass("A") }
        Resolver.default.register(MockClass.self, name: "B") { MockClass("B") }
        struct Demo {
            @Injected(name: "B") var mock: MockClass
        }
        #expect(Demo().mock.getGreetings("World") == "Hello B World")
    }
}

private struct MockClass {
    let value: String
    init(_ value: String = "") { self.value = value }
    func getGreetings(_ mgs: String) -> String {
        return "Hello \(value) \(mgs)"
    }
}
