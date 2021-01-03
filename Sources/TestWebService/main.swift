//
//  TestWebService.swift
//
//
//  Created by Paul Schmiedmayer on 7/6/20.
//
import Apodini
import ApodiniDatabase

struct TestWebService: Apodini.WebService {
    struct PrintGuard: SyncGuard {
        private let message: String

        init(_ message: String = "PrintGuard 👋") {
            self.message = message
        }
        

        func check() {
            print(message)
        }
    }
    
    struct EmojiMediator: ResponseTransformer {
        private let emojis: String
        
        
        init(emojis: String = "✅") {
            self.emojis = emojis
        }
        
        
        func transform(response: String) -> String {
            "\(emojis) \(response) \(emojis)"
        }
    }
    
    struct Greeter: Handler {
        @Properties
        var properties: [String: Apodini.Property] = ["surname": Parameter<String?>()]

        @Parameter(.http(.path))
        var name: String

        @Parameter
        var greet: String?

        func handle() -> String {
            let surnameParameter: Parameter<String?>? = _properties.typed(Parameter<String?>.self)["surname"]

            return "\(greet ?? "Hello") \(name) " + (surnameParameter?.wrappedValue ?? "Unknown")
        }
    }
    
    @propertyWrapper
    struct UselessWrapper: DynamicProperty {
        @Parameter var name: String?
        
        var wrappedValue: String? {
            name
        }
    }

    struct User: Codable {
        var id: Int
    }

    struct UserHandler: Handler {
        @Parameter var userId: Int

        func handle() -> User {
            User(id: userId)
        }
    }

    @PathParameter var userId: Int
    @PathParameter var dummy: String
    
    var content: some Component {
        Text("Hello World! 👋")
            .response(EmojiMediator(emojis: "🎉"))
            .response(EmojiMediator())
            .guard(PrintGuard())
        Group("swift") {
            Text("Hello Swift! 💻")
                .response(EmojiMediator())
                .guard(PrintGuard())
            Group("5", "3") {
                Text("Hello Swift 5! 💻")
            }
        }.guard(PrintGuard("Someone is accessing Swift 😎!!"))
        Group("greet") {
            Greeter()
                .serviceName("GreetService")
                .rpcName("greetMe")
                .response(EmojiMediator())
        }
        Group("user", $userId) {
            UserHandler(userId: $userId)
                .guard(PrintGuard())
        }
//        Group("api", "birds") {
//            Read<Bird>($dummy)
//            Create<Bird>()
//                .operation(.create)
//            Group($birdID) {
////                Get<Bird>(id: $birdID).operation(.read)
//                Update<Bird>(id: $birdID).operation(.update)
//            }
//        }
    }
    
    var configuration: Configuration {
//        DatabaseConfiguration(.defaultMongoDB(Environment.get("DATABASE_URL") ?? "mongodb://localhost:27017/vapor_database"))
//            .addMigrations(CreateBird())
        HTTP2Configuration()
    
    }
}

TestWebService.main()
