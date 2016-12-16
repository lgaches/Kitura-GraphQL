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


struct GraphQLRequestParams {
    let query: String?
    let operationName: String?
    let variables:[String: GraphQL.Map]
}

public let noRootValue: Void = Void()

public class GraphQLMiddleware<Root, Context>: RouterMiddleware {

    let schema: Schema<Root, Context>
    let showGraphiQL: Bool
    let rootValue: Root
    let context: Context?

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

        let params = parseParams(request: request)

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
            let result = try self.schema.execute(request: query, rootValue: rootValue, context: context ?? request as! Context, variables: params.variables, operationName: params.operationName)
            response.headers.append("Content-Type", value: "application/json")
            try response.send(json: convert(map: result)).end()
        } catch let error {
            try response.status(.badRequest).send(error.localizedDescription).end()
        }
    }

    func parseParams(request: RouterRequest) -> GraphQLRequestParams {

        switch request.method {
        case .get:
            let query = request.queryParameters["query"]?.removingPercentEncoding
            let operationName = request.queryParameters["operationName"]
            let variables = parseVariables(varsString: request.queryParameters["variables"])

            return GraphQLRequestParams(query: query, operationName: operationName, variables: variables)
        case .post:
            do {
                let content = try request.readString() ?? ""
                let json = JSON.parse(string: content)
                
                let query = json["query"].string
                let operationName = json["operationName"].string
                let variables = parseVariables(varsString: json["variables"].rawString())

                return GraphQLRequestParams(query: query, operationName: operationName, variables: variables)
            } catch {
                return GraphQLRequestParams(query: nil, operationName: nil, variables: [:])
            }
        default:
            return GraphQLRequestParams(query: nil, operationName: nil, variables: [:])
        }

    }

    func parseVariables(varsString: String?) -> [String: GraphQL.Map]  {
        guard let varsString = varsString else { return [:] }

        let varJson = JSON.parse(string: varsString)

        guard let vars = varJson.dictionary else { return [:] }

        var newVariables: [String: GraphQL.Map] = [:]
        for (key,value) in vars {
            newVariables[key] = convert(json: value)
        }

        return newVariables

    }

    func convert(json: JSON) -> GraphQL.Map {
        if let array = json.array {
            return GraphQL.Map.array(array.map({convert(json: $0)}))
        }

        if let string = json.string {
            return GraphQL.Map.string(string)
        }

        if let bool = json.bool {
            return GraphQL.Map.bool(bool)
        }

        if let double = json.double {
            return GraphQL.Map.double(double)
        }

        if let int = json.int {
            return GraphQL.Map.int(int)
        }

        if let dictionary = json.dictionary {
            var dict: [String: GraphQL.Map] = [:]
            for (key,value) in dictionary {
                dict[key] = convert(json: value)
            }

            return GraphQL.Map.dictionary(dict)
        }

        return GraphQL.Map.null
    }

    func convert(map: GraphQL.Map) -> JSON {
        return JSON.parse(string: map.description)
    }
}
