//
// Created by Andreas Bauer on 21.05.21.
//

// TODO docs?
#if swift(>=5.4)
@resultBuilder
public enum ComponentMetadataBuilder {}
#else
@_functionBuilder
public enum ComponentMetadataBuilder {}
#endif

// TODO note about how this needs to be its own thing, as otherwise we would have some abigous methods

public extension ComponentMetadataBuilder {
    static func buildExpression<Metadata: ComponentMetadataDeclaration>(_ expression: Metadata) -> AnyComponentMetadata {
        WrappedComponentMetadataDeclaration(expression)
    }

    static func buildExpression<Metadata: ComponentMetadataGroup>(_ expression: Metadata) -> AnyComponentMetadata {
        expression
    }

    static func buildOptional(_ component: AnyComponentMetadata?) -> AnyComponentMetadata {
        component ?? EmptyComponentMetadata()
    }

    static func buildEither(first: AnyComponentMetadata) -> AnyComponentMetadata {
        first
    }

    static func buildEither(second: AnyComponentMetadata) -> AnyComponentMetadata {
        second
    }

    static func buildArray(_ components: [AnyComponentMetadata]) -> AnyComponentMetadata {
        AnyComponentMetadataArrayWrapper(components)
    }

    static func buildBlock(_ components: AnyComponentMetadata...) -> AnyComponentMetadata {
        AnyComponentMetadataArrayWrapper(components)
    }
}
