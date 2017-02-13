import XCTest
import Graphiti
import Kitura
import KituraNet
import SwiftyJSON

@testable import GraphQLMiddleware


#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

let schema = try! Schema<NoRoot, NoContext> { schema in
    try schema.query { query in
        try query.field(name: "hello", type: String.self) { _ in
            "world"
        }
    }
}



class GraphQLMiddlewareTests: XCTestCase {
    let router = GraphQLMiddlewareTests.setupRouter()

    override func tearDown() {
        doTearDown()
    }

    func testGraphiQL() {
        performServerTest(router) { expectation in

            self.performRequest("get", path: "/graphql", callback: { response in

                guard let response = response else {
                    XCTFail("ClientRequest response object was nil")
                    expectation.fulfill()
                    return
                }

                do {
                    guard let body = try response.readString() else {
                        XCTFail("body in response is nil")
                        expectation.fulfill()
                        return
                    }

                    if body.range(of: "<!DOCTYPE html>") == nil || body.range(of: "GraphiQL") == nil {
                        XCTFail("No GraphiQL ")
                    }
                    XCTAssertNotNil(body)
                } catch {
                    XCTFail("No response body")
                }

                expectation.fulfill()
            })


        }

    }

    func testGraphqlQuery() {

        performServerTest(router) { expectation in
            self.performRequest("post", path: "/graphql", callback: { response in
                guard let response = response else {
                    XCTFail("ClientRequest response object was nil")
                    expectation.fulfill()
                    return
                }

                do {
                    guard let body = try response.readString() else {
                        XCTFail("body in response is nil")
                        expectation.fulfill()
                        return
                    }                    
                    let returnedJSON = JSON.parse(string: body)
                    XCTAssertEqual(returnedJSON, JSON(["data":["hello":"world"]]))
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }, headers: ["Content-Type": "application/json"], requestModifier: { request in
                do {
                    let jsonToTest = JSON(["query": "{ hello }"])
                    let jsonData = try jsonToTest.rawData()
                    request.write(from: jsonData)
                    request.write(from: "\n")
                } catch {
                    XCTFail("caught error \(error)")
                }
            })
        }
    }


    func testIntrospectionQuery() {

        performServerTest(router) { expectation in
            self.performRequest("post", path: "/graphql", callback: { response in
                guard let response = response else {
                    XCTFail("ClientRequest response object was nil")
                    expectation.fulfill()
                    return
                }

                do {
                    guard let body = try response.readString() else {
                        XCTFail("body in response is nil")
                        expectation.fulfill()
                        return
                    }

                    let returnedJSON = JSON.parse(string: body)

                    XCTAssertEqual(returnedJSON["data"]["__schema"].count, 5)
                    XCTAssertEqual(returnedJSON["data"]["__schema"]["types"].count, 11)
                    XCTAssertEqual(returnedJSON["data"]["__schema"]["directives"].count, 3)
                    XCTAssertEqual(returnedJSON["data"]["__schema"]["queryType"].count, 1)
                } catch {
                    XCTFail("No response body \(error)")
                }
                expectation.fulfill()
            }, headers: ["Content-Type": "application/json"], requestModifier: { request in
                do {
                    let bodyObject: [String : Any] = [
                        "query": "query IntrospectionQuery {    __schema {      queryType { name }      mutationType { name }      subscriptionType { name }      types {        ...FullType      }      directives {        name        description        locations        args {          ...InputValue        }      }    }  }  fragment FullType on __Type {    kind    name    description    fields(includeDeprecated: true) {      name      description      args {        ...InputValue      }      type {        ...TypeRef      }      isDeprecated      deprecationReason    }    inputFields {      ...InputValue    }    interfaces {      ...TypeRef    }    enumValues(includeDeprecated: true) {      name      description      isDeprecated      deprecationReason    }    possibleTypes {      ...TypeRef    }  }  fragment InputValue on __InputValue {    name    description    type { ...TypeRef }    defaultValue  }  fragment TypeRef on __Type {    kind    name    ofType {      kind      name      ofType {        kind        name        ofType {          kind          name          ofType {            kind            name            ofType {              kind              name              ofType {                kind                name                ofType {                  kind                  name                }              }            }          }        }      }    }  }",
                        "operationName": "IntrospectionQuery"
                    ]

                    let jsonToTest = JSON(bodyObject)
                    let jsonData = try jsonToTest.rawData()
                    request.write(from: jsonData)
                    request.write(from: "\n")
                } catch {
                    XCTFail("caught error \(error)")
                }
            })
        }
    }


    func testJSONtoMap() {
        let json = JSON(["string": "hello","array":["value1","value2"],"dico":["key1":"value1","key2":"value2"],"double": 20.3,"bool":true])
        let map = json.toGrapQLMap()
        XCTAssertTrue(map.isDictionary)
        XCTAssertTrue(map["string"].isString)
        XCTAssertEqual(map["string"].string, "hello")
        XCTAssertTrue(map["array"].isArray)
        XCTAssertTrue(map["dico"].isDictionary)
        XCTAssertTrue(map["double"].isDouble)
        XCTAssertTrue(map["bool"].isBool)


        let jsonArray = JSON(["value1","value2"])
        let mapArray = jsonArray.toGrapQLMap()

        XCTAssertTrue(mapArray.isArray)
        XCTAssertEqual(mapArray.array?.count, 2)
    }

    static func setupRouter() -> Router {
        let router = Router()
        router.all(middleware: GraphQLMiddleware(schema: schema, showGraphiQL: true, rootValue: noRootValue))

        router.get("/graphql") {_, response, next in
            do {
                try response.send("Graphql").end()
            } catch let error {
                print(error)
            }
            next()
        }

        return router
    }

    func testToMapDictionary() {
        let json = JSON(["query":"hello"])
        let result = json.toMapDictionary()
        XCTAssertEqual(result["query"]?.string, "hello")

        let noDico = JSON(["hello","Hola"])
        let resultMap = noDico.toMapDictionary()
        XCTAssertEqual(resultMap.count, 0)

    }

    static var allTests : [(String, (GraphQLMiddlewareTests) -> () throws -> Void)] {
        return [
            ("testGraphiQL", testGraphiQL),
            ("testGraphqlQuery", testGraphqlQuery),
            ("testIntrospectionQuery", testIntrospectionQuery),
            ("testJSONtoMap", testJSONtoMap)
        ]
    }
}
