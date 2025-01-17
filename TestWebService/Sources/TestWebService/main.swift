//
//  TestWebService.swift
//
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Apodini
import ApodiniREST
import ApodiniGRPC
import ApodiniProtobuffer
import ApodiniOpenAPI
import ApodiniWebSocket


struct TestWebService: Apodini.WebService {
    let greeterRelationship = Relationship(name: "greeter")

    var content: some Component {
        // Hello World! 👋
        Text("Hello World! 👋")
            .response(EmojiTransformer(emojis: "🎉"))

        // Bigger Subsystems:
        AuctionComponent()
        GreetComponent(greeterRelationship: greeterRelationship)
        RandomComponent(greeterRelationship: greeterRelationship)
        SwiftComponent()
        UserComponent(greeterRelationship: greeterRelationship)
    }
    
    var configuration: Configuration {
        OpenAPIConfiguration(
            outputFormat: .json,
            outputEndpoint: "oas",
            swaggerUiEndpoint: "oas-ui",
            title: "The great TestWebService - presented by Apodini"
        )
        ExporterConfiguration()
            .exporter(RESTInterfaceExporter.self)
            .exporter(GRPCInterfaceExporter.self)
            .exporter(ProtobufferInterfaceExporter.self)
            .exporter(OpenAPIInterfaceExporter.self)
            .exporter(WebSocketInterfaceExporter.self)
    }
}

try TestWebService.main()
