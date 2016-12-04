import XCTest
import Graphiti
import Kitura
import KituraNet


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



class Kitura_GraphQLTests: XCTestCase {
    let router = Kitura_GraphQLTests.setupRouter()

    override func tearDown() {
        doTearDown()
    }

    func testExample() {
        performServerTest(router) { expectation in

            

            self.performRequest("get", path: "/graphql", callback: { response in
                XCTAssertNotNil(response, "Response object was nil")
                //response?.headers[""]
                do {
                    let responseString = try response!.readString()

                    XCTAssertNotNil(responseString)
                } catch {
                    XCTFail("Can't read response body")
                }

                expectation.fulfill()
            })


            self.performRequest("post", path: "/graphql", callback: { response in
                
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

    static var allTests : [(String, (Kitura_GraphQLTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
