import NIO
import Vapor

/// `Configuration`s are used to register services to Apodini.
/// Each `Configuration` handles different kinds of services.
public protocol Configuration {
    /// A method that handles the configuration of a service which is called by the `main` function.
    ///
    /// - Parameter app: The `Vapor.Application` which is used to register the configuration in Apodini
    func configure(_ app: Application)
}


public protocol ConfigurationCollection {
    @ConfigurationBuilder var configuration: Configuration { get }
}


extension ConfigurationCollection {
    @ConfigurationBuilder public var configuration: Configuration {
        EmptyConfiguration()
    }
}


public struct EmptyConfiguration: Configuration {
    public func configure(_ app: Application) { }
    
    public init() { }
}


extension Array: Configuration where Element == Configuration {
    public func configure(_ app: Application) {
        forEach { $0.configure(app) }
    }
}
