import Graphiti


// Ensures string values are safe to be used within a <script> tag.
func safeSerialize(_ data: String?) -> String {
    //return data ? JSON.stringify(data).replace(/\//g, '\\/') : null;
    return data ?? "null"
}


/**
 * When GraphQLResponder receives a request which does not Accept JSON, but does
 * Accept HTML, it may present GraphiQL, the in-browser GraphQL explorer IDE.
 *
 * When shown, it will be pre-populated with the result of having executed the
 * requested query.
 */
func renderGraphiQL(query: String?, variables: [String: GraphQL.Map]?, operationName: String?, result: GraphQL.Map?) -> String {

    let variablesString = variables.map({ GraphQL.Map.dictionary($0).description })
    let resultString = result.map({ $0.description })

    return String(format: graphiqlHTML, safeSerialize(query),safeSerialize(resultString), safeSerialize(variablesString),safeSerialize(operationName))
}
