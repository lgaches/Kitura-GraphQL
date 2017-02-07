# Kitura GraphQL

[![Swift][swift-badge]][swift-url]
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
[![License][mit-badge]][mit-url]
[![Build Status](https://travis-ci.org/lgaches/Kitura-GraphQL.svg?branch=master)](https://travis-ci.org/lgaches/Kitura-GraphQL)
[![Codebeat][codebeat-badge]][codebeat-url]

Create a GraphQL HTTP server with [Kitura](http://www.kitura.io) web framework.

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/lgaches/Kitura-GraphQL.git", majorVersion: 0, minor: 0),
    ]
)
```

## Usage

### Configuration

`GraphQLMiddleware` has the following parameters:

- **`schema`**: A `Schema` instance from [`Graphiti`](https://github.com/GraphQLSwift/Graphiti). A `Schema` *must* be provided.
- **`showGraphiQL`**: If `true`, presentss [GraphiQL](https://github.com/graphql/graphiql) when the GraphQL endpoint is loaded in a browser. We recommend that you set `showGraphiQL` to `true` when your app is in development because it's quite useful. You may or may not want it in production. 
- **`rootValue`**: A value to pass as the `rootValue` to the schema's `execute` function from [`Graphiti`](https://github.com/GraphQLSwift/Graphiti).
- **`context`**: A value to pass as the `context` to the schema's `execute` function from [`Graphiti`](https://github.com/GraphQLSwift/Graphiti). If `context` is not provided, the `RouterRequest` struct is passed as the context.

### HTTP Usage

Once installed as a middleware at a path, `GraphQLMiddleware` will accept requests with the parameters:

- **`query`**: A string GraphQL document to be executed.
- **`operationName`**: If the provided query contains multiple named operations, this specifies which operation should be executed. If not provided, a 400 error will be returned if the query contains multiple named operations.
- **`variables`**: The runtime values to use for any GraphQL query variables as a JSON object.
- **`raw`**: If the `showGraphiQL` option is enabled and the raw parameter is provided raw JSON will always be returned instead of GraphiQL even when loaded from a browser.


### Example


```swift
import Graphiti
import Kitura
import GraphQLMiddleware

let schema = try Schema<NoRoot, NoContext> { schema in
    try schema.query { query in
        try query.field(name: "hello",
                        type: String.self,
                        description: "Totally Awesome",
                        deprecationReason: nil,
                        resolve: {
                            (type, arguments, context, resolveInfo) -> String in
                            return "world"
        })
    }
}

let router = Router()

let graphQL = GraphQLMiddleware(schema: schema,
                                showGraphiQL: true,
                                rootValue: noRootValue)

router.all("/graphql", middleware: graphQL)

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
