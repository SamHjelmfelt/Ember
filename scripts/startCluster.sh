#!/bin/bash

if [[ -z $1 ]]; then
  echo "Usage: $0 <configuration.ini> "
  exit -1
fi

iniFile=$1

clusterName=$(awk -F "=" '/clusterName/ {print $2}' $iniFile)

docker stop $(docker network inspect $clusterName | grep '"[a-zA-Z0-9]\{64\}": {' | awk -F "\"" '{print $2}')
