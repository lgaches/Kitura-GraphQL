//
//  GraphQLRequestParams.swift
//  Kitura-GraphQL
//
//  Created by Laurent Gaches on 13/02/2017.
//
//

import Foundation
import Kitura
import GraphQL
import SwiftyJSON

struct GraphQLRequestParams {
    let query: String?
    let operationName: String?
    let variables:[String: GraphQL.Map]

    init(request: RouterRequest) {
        switch request.method {
        case .get:
            self.query = request.queryParameters["query"]?.removingPercentEncoding
            self.operationName = request.queryParameters["operationName"]

            if let varsString = request.queryParameters["variables"] {
                self.variables = JSON.parse(string: varsString).toMapDictionary()
            } else {
                self.variables = [:]
            }

        case .post:
            do {
                let content = try request.readString() ?? ""
                let json = JSON.parse(string: content)

                self.query = json["query"].string
                self.operationName = json["operationName"].string
                self.variables = json["variables"].toMapDictionary()
            } catch {
                self.query = nil
                self.operationName = nil
                self.variables = [:]
            }
        default:
            self.query = nil
            self.operationName = nil
            self.variables = [:]
        }
    }
}
