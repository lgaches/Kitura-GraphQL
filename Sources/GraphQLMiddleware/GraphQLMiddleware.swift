//
//  GraphQLMiddleware.swift
//  Kitura-GraphQL
//
//  Created by Laurent Gaches on 16/11/2016.
//  Copyright (c) 2016 Laurent Gaches
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import Kitura
import SwiftyJSON
import GraphQL
import Graphiti
import LoggerAPI




public let noRootValue: Void = Void()

/// Kitura GraphQL Middleware
public class GraphQLMiddleware<Root, Context>: RouterMiddleware {

    let schema: Schema<Root, Context>
    let showGraphiQL: Bool
    let rootValue: Root
    let context: Context?

    /// Init Kitura GraphQL Middleware
    ///
    /// - Parameters:
    ///   - schema: A `Schema` instance from [Graphiti](https://github.com/GraphQLSwift/Graphiti). A `Schema` *must* be provided.
    ///   - showGraphiQL:If `true`, presentss [GraphiQL](https://github.com/graphql/graphiql) when the GraphQL endpoint is loaded in a browser. We recommend that you set `showGraphiQL` to `true` when your app is in development because it's quite useful. You may or may not want it in production.
    ///   - rootValue: A value to pass as the `rootValue` to the schema's `execute` function from [Graphiti](https://github.com/GraphQLSwift/Graphiti).
    ///   - context: A value to pass as the `context` to the schema's `execute` function from [Graphiti](https://github.com/GraphQLSwift/Graphiti).
    public init(schema: Schema<Root, Context>, showGraphiQL: Bool, rootValue: Root, context: Context? = nil) {
        self.schema = schema
        self.showGraphiQL = showGraphiQL
        self.rootValue = rootValue
        self.context = context
    }

    /// Handle an incoming HTTP request.
    ///
    /// - Parameter request: The `RouterRequest` object used to get information
    ///                     about the HTTP request.
    /// - Parameter response: The `RouterResponse` object used to respond to the
    ///                       HTTP request
    /// - Parameter next: The closure to invoke to enable the Router to check for
    ///                  other handlers or middleware to work with this request.
    ///
    /// - Throws: Any `ErrorType`. If an error is thrown, processing of the request
    ///          is stopped, the error handlers, if any are defined, will be invoked,
    ///          and the user will get a response with a status code of 500.
    public func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        let params = GraphQLRequestParams(request: request)

        switch request.method {
        // GraphQL HTTP only supports GET and POST methods.
        case .get:
            if !showGraphiQL || (showGraphiQL && request.queryParameters["raw"] != nil) {
                try executeGraphQLRequest(params: params, request: request, response: response)
            } else {
                if (showGraphiQL) {
                    let graphiql = renderGraphiQL(query: nil, variables: nil, operationName: nil, result: nil)
                    response.send(graphiql)
                    try response.end()
                } else {
                    response.status(.badRequest)
                    try response.send("Must provide query string.").end()
                }
            }

        case .post:
            if let _ = request.accepts(type:"application/json") {
                try executeGraphQLRequest(params: params, request: request, response: response)
            } else {
                response.status(.methodNotAllowed)
                try response.end()
            }
            
        default:
            response.headers.append("Allow",value: "GET, POST")
            response.status(.methodNotAllowed)
            try response.end()
        }
        
        next()
    }

    func executeGraphQLRequest(params: GraphQLRequestParams, request: RouterRequest, response: RouterResponse) throws {
        guard let query = params.query else {
            response.status(.badRequest)
            try response.send("Must provide query string.").end()
            return
        }


        do {
            let result: Map
            if let context = context {
                result = try self.schema.execute(request: query, rootValue: rootValue, context: context, variables: params.variables, operationName: params.operationName)
            } else {
                result = try self.schema.execute(request: query, rootValue: rootValue, variables: params.variables, operationName: params.operationName)
            }

            try response.send(json: result.toJSON()).end()
        } catch let error {
            print(error)
            try response.status(.badRequest).send(error.localizedDescription).end()
        }
    }

}
