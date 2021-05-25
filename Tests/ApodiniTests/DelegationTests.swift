//
//  DelegationTests.swift
//  
//
//  Created by Max Obermeier on 17.05.21.
//

@testable import Apodini
import ApodiniREST
import XCTApodini
import XCTVapor
import XCTest


final class DelegationTests: ApodiniTests {
    class TestObservable: Apodini.ObservableObject {
        @Apodini.Published var date: Date
        
        init() {
            self.date = Date()
        }
    }
    
    
    struct TestDelegate {
        @Parameter var message: String
        @Apodini.Environment(\.connection) var connection
        @ObservedObject var observable: TestObservable
    }
    
    struct TestHandler: Handler {
        let testD: Delegate<TestDelegate>
        
        @Parameter var name: String
        
        @Parameter var sendDate = false
        
        @Throws(.forbidden) var badUserNameError: ApodiniError
        
        @Apodini.Environment(\.connection) var connection
        
        init(_ observable: TestObservable? = nil) {
            self.testD = Delegate(TestDelegate(observable: observable ?? TestObservable()))
        }

        func handle() throws -> Apodini.Response<String> {
            guard name == "Max" else {
                switch connection.state {
                case .open:
                    return .send("Invalid Login")
                case .end:
                    return .final("Invalid Login")
                }
            }
            
            let delegate = try testD()
            
            switch delegate.connection.state {
            case .open:
                return .send(sendDate ? delegate.observable.date.timeIntervalSince1970.description : delegate.message)
            case .end:
                return .final(sendDate ? delegate.observable.date.timeIntervalSince1970.description : delegate.message)
            }
        }
    }

    func testValidDelegateCall() throws {
        var testHandler = TestHandler().inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Max", false, "Hello, World!")
        let context = endpoint.createConnectionContext(for: exporter)
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()),
            content: "Hello, World!",
            connectionEffect: .close
        )
    }
    
    func testMissingParameterDelegateCall() throws {
        var testHandler = TestHandler().inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Max")
        let context = endpoint.createConnectionContext(for: exporter)
        
        XCTAssertThrowsError(try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()).wait())
    }
    
    func testLazynessDelegateCall() throws {
        var testHandler = TestHandler().inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Not Max")
        let context = endpoint.createConnectionContext(for: exporter)
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()),
            content: "Invalid Login",
            connectionEffect: .close
        )
    }
    
    func testConnectionAwareDelegate() throws {
        var testHandler = TestHandler().inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Max", false, "Hello, Paul!", "Max", false, "Hello, World!")
        let context = endpoint.createConnectionContext(for: exporter)
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next(), final: false),
            content: "Hello, Paul!",
            connectionEffect: .open
        )
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()),
            content: "Hello, World!",
            connectionEffect: .close
        )
    }
    
    func testDelayedActivation() throws {
        var testHandler = TestHandler().inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Not Max", false, "Max", true, "")
        let context = endpoint.createConnectionContext(for: exporter)

        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next(), final: false),
            content: "Invalid Login",
            connectionEffect: .open
        )
        
        let before = Date().timeIntervalSince1970
        // this call is first to invoke delegate
        let response = try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()).wait()
        let observableInitializationTime = TimeInterval("\(response.content!.response.wrappedValue)")!
        XCTAssertGreaterThan(observableInitializationTime, before)
    }
    
    class TestListener: ObservedListener {
        var eventLoop: EventLoop
        
        var result: EventLoopFuture<TimeInterval>?
        
        init(eventLoop: EventLoop) {
            self.eventLoop = eventLoop
        }

        func onObservedDidChange(_ observedObject: AnyObservedObject, in context: ConnectionContext<MockExporter<String>>) {
            result = context.handle(eventLoop: eventLoop, observedObject: observedObject).map { response in
                TimeInterval("\(response.content!.response.wrappedValue)")!
            }
        }
    }
    
    func testObservability() throws {
        let eventLoop = app.eventLoopGroup.next()
        
        let listener = TestListener(eventLoop: eventLoop)
        
        let observable = TestObservable()
        var testHandler = TestHandler(observable).inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Not Max", false, "Max", true, "", "Max", true, "", "Not Max", false)
        let context = endpoint.createConnectionContext(for: exporter)
        context.register(listener: listener)

        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: eventLoop, final: false),
            content: "Invalid Login",
            connectionEffect: .open
        )
        
        // should not fire
        observable.date = Date()
        
        // this call is first to invoke delegate
        _ = try context.handle(request: "Example Request", eventLoop: eventLoop, final: false).wait()
        
        // should trigger third evaluation
        let date = Date()
        observable.date = date
        
        let result = try listener.result?.wait()
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, date.timeIntervalSince1970)
        
        // final evaluation
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: eventLoop),
            content: "Invalid Login",
            connectionEffect: .close
        )
    }
}