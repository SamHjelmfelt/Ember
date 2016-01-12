#!/bin/bash

if [[ -z $1 ]]; then
  echo "Usage: $0 <cluster name>"
  exit -1
fi

curl -u admin:admin -L http://localhost:8080/api/v1/clusters/$1?format=blueprint
