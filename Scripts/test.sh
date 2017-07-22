#!/usr/bin/env bash

set -exo pipefail

docker build -t kitura_graphql_test -f Dockerfile ./

finish () {
	echo "finish"
}

set +e

docker run --rm kitura_graphql_test \
  || (finish; set +x; echo -e "\033[0;31mTests exited with non-zero exit code\033[0m"; tput bel; exit 1 )
  
finish;