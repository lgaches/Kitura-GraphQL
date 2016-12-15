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

let schema = try! Schema<Void> { schema in
    schema.query = try ObjectType(name: "RootQueryType") { query in
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

    static var allTests : [(String, (GraphQLMiddlewareTests) -> () throws -> Void)] {
        return [
            ("testGraphiQL", testGraphiQL),
            ("testGraphqlQuery", testGraphqlQuery)
        ]
    }
}
