import XCTest
import Graphiti
@testable import GraphQLMiddleware

let schema = try! Schema<Void> { schema in
    schema.query = try ObjectType(name: "RootQueryType") { query in
        try query.field(name: "hello", type: String.self) { _ in
            "world"
        }
    }
}

let graphql = GraphQLMiddleware(schema: schema, showGraphiQL: true, rootValue: noRootValue)

class Kitura_GraphQLTests: XCTestCase {
    func testExample() {


        XCTAssertNotNil(graphql)
    }


    static var allTests : [(String, (Kitura_GraphQLTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
