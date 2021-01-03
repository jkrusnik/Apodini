//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-29.
//

import Foundation
import XCTest
import Vapor
@testable import Apodini


final class HandlerIdentifierTests: ApodiniTests {
    struct TestHandlerType: IdentifiableHandler {
        typealias Response = Never
        let handlerId = ScopedHandlerIdentifier<Self>("main")
    }
    
    
    func testScopedHandlerIdentifier() {
        XCTAssertEqual(TestHandlerType().handlerId, AnyHandlerIdentifier("TestHandlerType.main"))
    }
    
    func testDefaultHandlerIdentifier() {
        struct TestWebService: WebService {
            var content: some Component {
                Group("x") {
                    Text("a")
                }
                Group("x/y") {
                    Text("b")
                }
            }
        }
        
        let SSMBuilder = SharedSemanticModelBuilder(app)
        TestWebService().register(SSMBuilder)
        let allEndpoints = SSMBuilder.rootNode.collectAllEndpoints()
        
        XCTAssertEqual(allEndpoints.count, 2)
        
        print(allEndpoints.map(\.identifier.rawValue))
        
        XCTAssertTrue(allEndpoints.contains(where: { endpoint in
            endpoint.identifier.rawValue == "0:0"
                && endpoint.description == String(describing: Text("a"))
        }))
        XCTAssertTrue(allEndpoints.contains(where: { endpoint in
            endpoint.identifier.rawValue == "1:0"
                && endpoint.description == String(describing: Text("b"))
        }))
    }
    
    func testDefaultHandlerIdentifier2() {
        struct TestWebService: WebService {
            var content: some Component {
                Text("a")
                Text("b")
                    .operation(.create)
                Group("x") {
                    Text("c")
                }
                Group("x/y") {
                    Text("d")
                }
            }
        }
        
        let SSMBuilder = SharedSemanticModelBuilder(app)
        TestWebService().register(SSMBuilder)
        let allEndpoints = SSMBuilder.rootNode.collectAllEndpoints()
        
        XCTAssertEqual(allEndpoints.count, 4)
        
        print(allEndpoints.map(\.identifier.rawValue))
        
        XCTAssertTrue(allEndpoints.contains(where: { endpoint in
            endpoint.identifier.rawValue == "0"
                && endpoint.description == String(describing: Text("a"))
        }))
        XCTAssertTrue(allEndpoints.contains(where: { endpoint in
            endpoint.identifier.rawValue == "1"
                && endpoint.description == String(describing: Text("b"))
        }))
        XCTAssertTrue(allEndpoints.contains(where: { endpoint in
            endpoint.identifier.rawValue == "2:0"
                && endpoint.description == String(describing: Text("c"))
        }))
        XCTAssertTrue(allEndpoints.contains(where: { endpoint in
            endpoint.identifier.rawValue == "3:0"
                && endpoint.description == String(describing: Text("d"))
        }))
    }
    
    func testDefaultHandlerIdentifier3() {
        struct TestWebService: WebService {
            var content: some Component {
                Group("x/y") {
                    Group("z") {
                        Text("a")
                    }
                }
                Text("b")
            }
        }
        
        let SSMBuilder = SharedSemanticModelBuilder(app)
        TestWebService().register(SSMBuilder)
        let allEndpoints = SSMBuilder.rootNode.collectAllEndpoints()
        
        XCTAssertEqual(allEndpoints.count, 2)
        
        print(allEndpoints.map(\.identifier.rawValue))
        
        XCTAssertTrue(allEndpoints.contains(where: { endpoint in
            endpoint.identifier.rawValue == "0:0:0"
                && endpoint.description == String(describing: Text("a"))
        }))
        XCTAssertTrue(allEndpoints.contains(where: { endpoint in
            endpoint.identifier.rawValue == "1"
                && endpoint.description == String(describing: Text("b"))
        }))
    }
}