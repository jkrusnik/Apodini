import Foundation
import XCTest
import NIO
import Vapor
import Fluent
import Runtime
@testable import Apodini
@testable import ApodiniDatabase

final class DatabaseHandlerTests: ApodiniTests {
    
    var vaporApp: Vapor.Application {
        self.app.vapor.app
    }
    
    private func pathParameter(for handler: Any) throws -> Parameter<UUID> {
        let mirror = Mirror(reflecting: handler)
        let parameter = mirror.children.compactMap { $0.value as? Parameter<UUID> }.first
        guard let idParameter = parameter else {
            //No point in continuing if there is no parameter
            fatalError("no idParameter found")
        }
        return idParameter
    }

    func testCreateHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.db)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(dbBird.id)
        
        let creationHandler = Create<Bird>()
        
        let request = MockRequest.createRequest(on: creationHandler, running: app.eventLoopGroup.next(), queuedParameters: bird)
        let response = request.enterRequestContext(with: creationHandler, executing: { component in
            component.handle()
        })
        XCTAssertNotNil(response)
        XCTAssert(response == bird)
        
        let foundBird = try Bird.find(dbBird.id, on: app.db).wait()
        XCTAssertNotNil(foundBird)
        XCTAssertEqual(dbBird, foundBird)
    }
    
    func testReadHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.db)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(dbBird.id)
        
        let readHandler = Read<Bird>()
        let endpoint = readHandler.mockEndpoint()

        let exporter = RESTInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)

        let uri = URI("http://example.de/test/bird?name=Mockingbird")
        let request = Vapor.Request(
            application: vaporApp,
                method: .GET,
                url: uri,
                on: app.eventLoopGroup.next()
        )
//        request.parameters.set("name", to: "Mockingbird")
//        request.parameters.set("age", to: "6")
        
        let result = try context.handle(request: request).wait()
        guard case let .final(responseValue) = result.typed(String.self) else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        
        let queryBuilder = QueryBuilder(
            type: Bird.self,
            parameters: [
                Bird.fieldKey(for: "name"): AnyCodable(.string("Mockingbird"))
            ]
        )
        //As Eventloops are currently not working, only the queryBuilder is tested right now.
        XCTAssertEqual(responseValue, queryBuilder.debugDescription)
    }
    
    func testUpdateHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.db)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(dbBird.id)
        
        var varBird = dbBird
        let info = try! typeInfo(of: Bird.self)
        print(info)
        let property = try! info.property(named: "_name")
        let name = try! property.get(from: varBird)
            
        print(name)
        print(varBird)
        try! property.set(value: "Test", on: &varBird)
        print(varBird)
        
        
        
        
        let updatedBird = Bird(name: "FooBird", age: 25)
        let parameters: [String: AnyCodable] = [
            "name": AnyCodable("FooBird"),
//            "age": AnyCodable(25)
        ]
        
        let handler = Update<Bird>()
        let endpoint = handler.mockEndpoint()

        let exporter = RESTInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)

        let bodyData = ByteBuffer(data: try JSONEncoder().encode(parameters))

        let uri = URI("http://example.de/test/id")
        let request = Vapor.Request(
                application: vaporApp,
                method: .PUT,
                url: uri,
                collectedBody: bodyData,
                on: app.eventLoopGroup.next()
        )
        guard let birdId = dbBird.id else {
            XCTFail("Object found in db has no id")
            return
        }
        let idParameter = try pathParameter(for: handler)
        request.parameters.set("\(idParameter.id)", to: "\(birdId)")
        
        let result = try context.handle(request: request).wait()
        
        guard case let .final(responseValue) = result.typed(String.self) else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        
        XCTAssert(responseValue == "success")
        expectation(description: "database access").isInverted = true
        waitForExpectations(timeout: 10, handler: nil)
        guard let newBird = try Bird.find(dbBird.id, on: self.app.db).wait() else {
            XCTFail("Failed to find updated object")
            return
        }

        XCTAssertNotNil(newBird)
        XCTAssert(newBird.name == updatedBird.name, newBird.description)
        XCTAssert(newBird.age == 25, newBird.description)
    }
    
    func testDeleteHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.db)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(dbBird.id)
        
        let handler = Delete<Bird>()
        let endpoint = handler.mockEndpoint()

        let exporter = RESTInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)

        let uri = URI("http://example.de/test/id")
        let request = Vapor.Request(
                application: vaporApp,
                method: .PUT,
                url: uri,
                on: app.eventLoopGroup.next()
        )
        
        guard let birdId = dbBird.id else {
            XCTFail("Object found in db has no id")
            return
        }
        
        let idParameter = try pathParameter(for: handler)
        request.parameters.set(":\(idParameter.id)", to: "\(birdId)")
        
        let result = try context.handle(request: request).wait()
        guard case let .final(response) = result.typed(String.self) else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        
        XCTAssertEqual(response, String(HTTPStatus.ok.code))
        expectation(description: "database access").isInverted = true
        waitForExpectations(timeout: 10, handler: nil)
        
        let deletedBird = try Bird.find(dbBird.id, on: app.db).wait()
        XCTAssertNil(deletedBird)
    }
}