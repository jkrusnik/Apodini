//
//  API.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

public struct Version: PathComponent {
    public enum Defaults {
        public static let prefix: String = "v"
        public static let major: UInt = 1
        public static let minor: UInt = 0
        public static let patch: UInt = 0
    }
    
    
    public let prefix: String
    public let major: UInt
    public let minor: UInt
    public let patch: UInt
    
    
    public init(prefix: String = Defaults.prefix,
                major: UInt = Defaults.major,
                minor: UInt = Defaults.minor,
                patch: UInt = Defaults.patch) {
        self.prefix = prefix
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    
    public func append<P>(to pathBuilder: inout P) where P : PathBuilder {
        pathBuilder.append("\(prefix)\(major)")
    }
}

public struct APIVersionContextKey: ContextKey {
    public static var defaultValue: Version = Version()
    
    public static func reduce(value: inout Version, nextValue: () -> Version) {
        value = nextValue()
    }
}