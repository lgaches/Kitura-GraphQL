

OUTPUT=`tr -s '\n' ' ' < ../Configuration/GraphiQL.html`
echo $OUTPUT > TMP_FILE
OUTPUT2=`sed 's/["'"'"']/\\\"/g' TMP_FILE` 
echo "let graphiqlHTML=\"$OUTPUT2\"" > ../Sources/GraphQLMiddleware/GraphiQL+HTML.swift
rm TMP_FILE

