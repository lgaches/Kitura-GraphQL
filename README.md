# Kitura GraphQL

[![Swift][swift-badge]][swift-url]
[![License][mit-badge]][mit-url]
[![Codebeat][codebeat-badge]][codebeat-url]

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/lgaches/Kitura-GraphQL.git", majorVersion: 0, minor: 1),
    ]
)
```

## Usage

### Configuration

### Example
Example using [Kitura](http://www.kitura.io)

```swift
import Graphiti
import Kitura
import GraphQLMiddleware

let schema = try Schema<Void> { schema in
    schema.query = try ObjectType(name: "RootQueryType") { query in
        try query.field(name: "hello", type: String.self) { _ in
            "world"
        }
    }
}


let router = Router()

let graphql = GraphQLMiddleware(schema: schema, showGraphiQL: true, rootValue: noRootValue)


router.all("/graphql", middleware: graphql)

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()

```

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.0.1-orange.svg?style=flat
[swift-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[codebeat-badge]:https://codebeat.co/badges/7871a224-095f-4c39-b5fb-bfa6320cdadd
[codebeat-url]: https://codebeat.co/projects/github-com-lgaches-kitura-graphql
