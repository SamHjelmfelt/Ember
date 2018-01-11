#!/bin/bash

if [[ -z $1 ]]; then
  echo "Usage: $0 <configuration.ini> "
  exit -1
fi

iniFile=$1

clusterName=$(awk -F "=" '/clusterName/ {print $2}' $iniFile)

docker kill $(docker ps -a | grep ".*.$clusterName" | cut -f1 -d" ")
