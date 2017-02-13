//
//  SwiftyJSONGraphQLMap.swift
//  Kitura-GraphQL
//
//  Created by Laurent Gaches on 13/02/2017.
//
//

import Foundation
import GraphQL
import SwiftyJSON

extension JSON {

    public func toGrapQLMap() -> GraphQL.Map {
        if let array = self.array {
            return GraphQL.Map.array(array.map({$0.toGrapQLMap()}))
        }

        if let string = self.string {
            return GraphQL.Map.string(string)
        }

        if let bool = self.bool {
            return GraphQL.Map.bool(bool)
        }

        if let double = self.double {
            return GraphQL.Map.double(double)
        }

        if let int = self.int {
            return GraphQL.Map.int(int)
        }


        if let dictionary = self.dictionary {
            var dict: [String: GraphQL.Map] = [:]
            for (key,value) in dictionary {
                dict[key] = value.toGrapQLMap()
            }

            return GraphQL.Map.dictionary(dict)
        }

        return GraphQL.Map.null
    }


    func toMapDictionary() -> [String: GraphQL.Map]  {

        guard let vars = self.dictionary else { return [:] }

        var newVariables: [String: GraphQL.Map] = [:]
        for (key,value) in vars {
            newVariables[key] = value.toGrapQLMap()
        }

        return newVariables
    }
}

extension GraphQL.Map {
    public func toJSON() -> SwiftyJSON.JSON {
        return JSON(serialize(map: self))
    }


    private func serialize(map: GraphQL.Map) -> Any {
        switch map {
        case .dictionary(let dictionnary): return serialize(dictionary: dictionnary)
        case .array(let array): return serialize(array: array)
        case .string(let string): return string
        case .double(let number): return number
        case .int(let number): return number
        case .bool(let bool): return bool
        case .null: return NSNull()
        }

    }

    private func serialize(dictionary: [String: Map]) -> Dictionary<String, Any> {
        var dico = Dictionary<String, Any>()
        for (key, value) in dictionary.sorted(by: {$0.0 < $1.0})  {
            dico[key] = serialize(map: value)
        }
        return dico
    }

    private func serialize(array: [Map]) -> [Any] {
        var ar = [Any]()
        for element in array {
            ar.append(serialize(map: element))
        }
        
        return ar
    }
}
