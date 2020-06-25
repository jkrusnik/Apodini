import NIO


protocol Component: Visitable {
    associatedtype Content: Component
    associatedtype Response: Codable
    
    var content: Content { get }
    
    func handle(_ request: Request) -> EventLoopFuture<Response>
}

extension Component {
    func executeInContext(of request: Request) -> EventLoopFuture<Response> {
        request.executeInContext(self)
    }
}

extension Component {
    // func visit<V: Visitor>(_ visitor: inout V) { }
}
