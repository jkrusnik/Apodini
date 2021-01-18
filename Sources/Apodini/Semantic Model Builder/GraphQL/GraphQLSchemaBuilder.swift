//
// Created by Sadik Ekin Ozbay on 06.01.21.
//

@_implementationOnly import Vapor
import GraphQL


// GraphQL EventLoop return handler
//let GraphQLEventLoop = try! GraphQLScalarType(
//        name: "EventLoop",
//        description:
//        "The `EventLoop(String)` scalar type represents textual data, represented as UTF-8 " +
//                "character sequences. The String type is most often used by GraphQL to " +
//                "represent free-form human-readable text.",
//        serialize: { val in
//            var res = String()
//            // TODO: It does work but why ?
//            (val as! EventLoopFuture<String>).whenSuccess { s in
//                res = s
//            }
//            return try map(from: res)
//        },
//        parseValue: {
//            print("parseValue->", type(of: $0), $0)
//            return try .string($0.stringValue(converting: true))
//        },
//        parseLiteral: { ast in
//            print("parseLiteral->", type(of: ast), ast)
//            if let ast = ast as? StringValue {
//                return .string(ast.value)
//            }
//
//            return .null
//        }
//)

func graphqlTypeMap(with type: Codable.Type) -> GraphQLScalarType {
    if (type == String.self) {
        return GraphQLString
    } else if (type == Int.self) {
        return GraphQLInt
    } else if (type == Float.self) {
        return GraphQLFloat
    } else if (type == Bool.self) {
        return GraphQLBoolean
    }
    return GraphQLString

}

struct GraphQLRequest: ExporterRequest {
    var source: Any
    var args: Map
    var context: Any
    var info: GraphQLResolveInfo
}


//struct GraphQLResponseContainer: Encodable {
//    var data: AnyEncodable?
//
//    init(_ data: AnyEncodable?) {
//        self.data = data
//    }
//
//    func encodeResponse(with responseTransformers: [AnyResponseTransformer]) -> Any {
////        if let stringData = self.data?.wrappedValue as? String {
////            return stringData
////        }
//
//
//        let jsonEncoder = JSONEncoder()
//        jsonEncoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
//
//        var response = String()
//        do {
//            if let currentData = self.data {
//                var transformedData = currentData
////                for rt in responseTransformers { // TODO: transforms
////                    transformedData = AnyEncodable(rt.transform(response: transformedData))
////                }
//
//                // print("Current data is ", transformedData.value)
//                let encodedData = try jsonEncoder.encode(transformedData)
//                response = String(data: encodedData, encoding: .utf8)!
//            }
//        } catch {
//            response = "Error happened in the data encoding!"
//        }
//
//
//        return response
//    }
//}

class GraphQLSchemaBuilder {
    private var tree = [String: Set<String>]()
    private var leafHandler = [String: AnyConnectionContext<GraphQLInterfaceExporter>]()
    //private var leafHandlerResponseType = [String: Encodable.Type]()
    private var hasIncomingEdge = Set<String>()


    // GraphQL Related values
    private var types = [String: GraphQLObjectType]()
    private var fields = [String: GraphQLField]()
    private var args = [String: [String: GraphQLArgument]]()
    private var responseTransformers = [String: [AnyResponseTransformer]]()
    private var responseTypeTree = [String: Node<EnrichedInfo>]()

    // TODO: Handle array types
    private func responseTypeHandler(for responseTypeHead: Node<EnrichedInfo>) -> GraphQLOutputType {
        if (responseTypeHead.value.typeInfo.type == String.self) {
            return GraphQLString
        }
        if (responseTypeHead.value.typeInfo.type == Int.self) {
            return GraphQLInt
        }
        if (responseTypeHead.value.typeInfo.type == Bool.self) {
            return GraphQLBoolean
        }
        if (responseTypeHead.value.typeInfo.type == Float.self) {
            return GraphQLFloat
        }
        var currentFields = [String: GraphQLField]()
        for c in responseTypeHead.children {
            if let childName = c.value.propertyInfo?.name {
                currentFields[childName] = GraphQLField(type: responseTypeHandler(for: c))
            }
        }
        return try! GraphQLObjectType(name: responseTypeHead.value.typeInfo.name, fields: currentFields, isTypeOf: { source, _, info in
            print("The info is ->", info)
            print("The source is ->", source)
            print(type(of: source))
            print(responseTypeHead.value.typeInfo.type)

           //print(type(of: source).self === type(of: responseTypeHead.value.typeInfo.type).self)

            return true // source is String // TODO: Fix this with the real value of return type e.g. User
        })
    }

    private func graphQLFieldCreator(for responseTypeHead: Node<EnrichedInfo>, _ context: AnyConnectionContext<GraphQLInterfaceExporter>, _ args: [String: GraphQLArgument], _ responseTransformers: [AnyResponseTransformer]) -> GraphQLField {
        var mutableContext = context
        let graphQLFieldType = self.responseTypeHandler(for: responseTypeHead)
        return GraphQLField(type: graphQLFieldType, args: args, resolve: { gSource, gArgs, gContext, gInfo in
            let request = GraphQLRequest(source: gSource, args: gArgs, context: gContext, info: gInfo)
            let vaporRequest = gContext as! Vapor.Request
            var response: EventLoopFuture<Response<AnyEncodable>> = mutableContext.handle(request: request, eventLoop: vaporRequest.eventLoop.next())
//            print("The tpe info is ",  responseTypeHead.value.typeInfo.properties)
//            var dict = [String: Any]()
//            for p in responseTypeHead.value.typeInfo.properties{
//                dict[p.name] = "12"
//            }
//            print("The dict is", dict)
////            let dict =
//            let val : Encodable = try JSONDecoder().decode(responseTypeHead.value.typeInfo.type, from: JSONSerialization.data(withJSONObject: dict))
//            print(val)
////            // TODO: Transformer
//            for rt in responseTransformers {
//                transformedData = AnyEncodable(rt.transform(response: transformedData))
//            }
//            print("REsponse type is", gInfo.returnType)
            let res = response.flatMapThrowing { encodableAction -> String  in
                switch encodableAction {
                case let .send(element),
                     let .final(element):
                    print("The element is ", element)

//                    print(encodedData)
                    return "HI"
                case .nothing, .end:
                    return "EMPTY?"
                }
            }

            var mainRes = String()

            res.whenSuccess { s in
                mainRes = s
            }
            print("The main res is ", mainRes)
            // let dict : [String : Any] =
            return "HI"
        })
    }

    // Generated adjacency list tree
    func append<H: Handler>(for endpoint: Endpoint<H>, with context: AnyConnectionContext<GraphQLInterfaceExporter>) {
        let treeTemp = try! EnrichedInfo.node(endpoint.handleReturnType)
//        print(self.responseTypeHandler(for: treeTemp))


        var currentPath = endpoint.absolutePath.map {
            $0.description.lowercased()
        }.filter {
            $0.first != ":"
        }

        // TODO: Does starting ":" indicate Parameter? Because it is in the path
        // TODO: e.g. ->> ["v1", "user", ":1234-asdf-12341234"]
        currentPath.removeFirst()

        // Create node names
        var currentSum = String()
        if (currentPath.count > 1) {
            for ix in 0..<currentPath.count {
                currentSum.append(currentPath[ix])
                currentSum.append("_")
                currentPath[ix] = currentSum
            }
        }

        // Get leaf name
        let leafName = currentPath.last ?? "None"

        // Handle response transformer
        self.responseTransformers[leafName] = endpoint.responseTransformers.map {
            $0()
        }

        // Handle arguments
        for p in endpoint.parameters {
            let graphqlType = graphqlTypeMap(with: p.propertyType)
            if (p.necessity == .required) {
                self.args[leafName, default: [:]][p.name] = GraphQLArgument(type: GraphQLNonNull(graphqlType), description: p.description)
            } else {
                self.args[leafName, default: [:]][p.name] = GraphQLArgument(type: graphqlType, description: p.description)
            }

        }

        self.responseTypeTree[leafName] = treeTemp

        // Handle Single points
        if (currentPath.count == 1) {
            self.fields[leafName] = self.graphQLFieldCreator(for: self.responseTypeTree[leafName]!,
                    context,
                    self.args[leafName] ?? [:],
                    self.responseTransformers[leafName] ?? [])
            return
        }

        // Create handler
        self.leafHandler[leafName] = context

        // Create tree
        var indx = currentPath.count - 1
        while (indx >= 1) {
            let child = currentPath[indx], parent = currentPath[indx - 1]
            if (self.tree.keys.contains(parent)) {
                self.tree[parent]!.insert(child)
            } else {
                self.tree[parent] = [child]
            }
            hasIncomingEdge.insert(child)
            indx -= 1
        }


    }

    private func nameExtractor(for node: String) -> String {
        node.components(separatedBy: "_").filter({ $0 != "" }).last ?? "None"
    }

    private func generateSchemaFromTreeHelper(_ node: String) -> GraphQLField {
        let nodeName = self.nameExtractor(for: node)
        if let childrenList = self.tree[node] {
            var currentFields = [String: GraphQLField]()
            for child in childrenList {
                let childName = child.components(separatedBy: "_").filter({ $0 != "" }).last ?? "None"
                currentFields[childName] = generateSchemaFromTreeHelper(child)
            }
            self.types[nodeName] = try! GraphQLObjectType(name: nodeName, fields: currentFields)

            return GraphQLField(type: self.types[nodeName]!, resolve: { _, _, _, _ in "Emtpy" })
        } else {
            return self.graphQLFieldCreator(for: self.responseTypeTree[node]!,
                    self.leafHandler[node]!,
                    self.args[node] ?? [:],
                    self.responseTransformers[node] ?? [])
        }
    }

    private func generateSchemaFromTree() {
        for (parent, _) in self.tree {
            // It is one of the roots
            if (!self.hasIncomingEdge.contains(parent)) {
                let parentName = self.nameExtractor(for: parent)
                self.fields[parentName] = generateSchemaFromTreeHelper(parent)
            }
        }
    }

    func generate() -> GraphQLSchema {
        self.generateSchemaFromTree()
        print(fields)
        let queryType = try! GraphQLObjectType(
                name: "Apodini",
                fields: self.fields
        )
        return try! GraphQLSchema(
                query: queryType,
                types: Array(self.types.values)
        )
    }
}