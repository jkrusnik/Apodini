//
//  ProxyServer.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-02.
//

import Foundation
import Vapor
import ApodiniDeployBuildSupport
import DeploymentTargetLocalhostCommon
import Logging
import OpenAPIKit
import class Apodini.AnyHandlerIdentifier


class ProxyServer {
    struct Error: Swift.Error {
        let message: String
    }
    
    fileprivate let app: Vapor.Application
    fileprivate let logger = Logger(label: "DeploymentTargetLocalhost.ProxyServer")
    
    init(openApiDocument: OpenAPI.Document, deployedSystem: DeployedSystem) throws {
        let environmentName = try Vapor.Environment.detect().name
        var env = Vapor.Environment(name: environmentName, arguments: ["vapor"])
        try LoggingSystem.bootstrap(from: &env)
        self.app = Application(env)
        for (path, pathItem) in openApiDocument.paths {
            for endpoint in pathItem.endpoints {
                guard let handlerIdRawValue = endpoint.operation.vendorExtensions["x-apodiniHandlerId"]?.value as? String else {
                    throw Error(message: "Unable to read handlerId from OpenAPI document")
                }
                guard let targetNode = deployedSystem.nodeExportingEndpoint(withHandlerId: AnyHandlerIdentifier(handlerIdRawValue)) else {
                    throw Error(message: "Unable to find node for handler id '\(handlerIdRawValue)'")
                }
                app.add(Vapor.Route(
                    method: Vapor.HTTPMethod(rawValue: endpoint.method.rawValue),
                    path: path.toVaporPath(),
                    responder: ProxyRequestResponder(proxyServer: self, targetNode: targetNode),
                    requestType: Vapor.Request.self,
                    responseType: EventLoopFuture<Vapor.ClientResponse>.self
                ))
            }
        }
    }
    
    
    deinit {
        // If for some reason the vapor application hasn't been shut down by the time the ProxyServer is destructed,
        // we manually shut it down in here.
        // The main cause for -deinit getting called when the application before the application was shut down is if the
        // initializer fails (ie throws an error).
        // In that case run will never get called, meaning the app isn't yet shut down
        if !app.didShutdown {
            app.shutdown()
        }
    }
    
    /// Start the proxy
    func run(port: Int) throws {
        logger.notice("\(#function)")
        defer {
            logger.notice("shutdown")
            app.shutdown()
        }
        app.http.server.configuration.port = port
        logger.notice("Starting Vapor application")
        try app.run()
    }
}


extension OpenAPI.Path {
    func toVaporPath() -> [Vapor.PathComponent] {
        self.components.map { component -> Vapor.PathComponent in
            if component.hasPrefix("{") && component.hasSuffix("}") {
                return .anything
            } else {
                return .constant(component)
            }
        }
    }
}


private struct ProxyRequestResponder: Vapor.Responder {
    let proxyServer: ProxyServer
    let targetNode: DeployedSystem.Node
    
    func respond(to request: Request) -> EventLoopFuture<Vapor.Response> {
        guard let targetNodeLocalhostData = targetNode.readUserInfo(as: LocalhostLaunchInfo.self) else {
            fatalError("Unable to read node userInfo")
        }
        let url = Vapor.URI(
            scheme: "http",
            host: "127.0.0.1",
            port: targetNodeLocalhostData.port,
            path: request.url.path,
            query: request.url.query,
            fragment: request.url.fragment
        )
        proxyServer.logger.notice("forwarding request to '\(url)'")
        let clientResponseFuture = request.client.send(request.method, headers: request.headers, to: url) { (clientReq: inout ClientRequest) in
            clientReq.body = request.body.data
        }
        return clientResponseFuture.flatMap { clientResponse in
            // Note: For some reason, Vapor will duplicate some header fields when sending this response back to the client.
            // The ones i noticed were `date` and `connection`, but that's probably not the full list.
            let ignoredHeaderFields: [HTTPHeaders.Name] = [.date, .connection]
            let response = Response(
                status: clientResponse.status,
                //version, // `ClientResponse` doesn't have a version, we could use the default (what we're doing) or return the initial request's version
                headers: HTTPHeaders(clientResponse.headers.filter { !ignoredHeaderFields.contains(HTTPHeaders.Name($0.name)) }),
                body: clientResponse.body.map { Response.Body(buffer: $0) } ?? .empty
            )
            return proxyServer.app.eventLoopGroup.next().makeSucceededFuture(response)
        }
    }
}
