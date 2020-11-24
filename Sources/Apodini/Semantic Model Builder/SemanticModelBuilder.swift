//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 11/3/20.
//

import Vapor


class SemanticModelBuilder {
    private(set) var app: Application
    
    
    init(_ app: Application) {
        self.app = app
    }
    
    
    func register<C: Component>(component: C, withContext context: Context) { }
    func decode<T: Decodable>(_ type: T.Type, from request: Vapor.Request) throws -> T? {
        fatalError("decode must be overridden")
    }
}
