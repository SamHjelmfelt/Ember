#!/bin/bash
if [[ -z $1 ]]; then
    docker stats $(docker ps --format '{{.Names}}')
else

    iniFile=$1
    clusterName=$(awk -F "=" '/clusterName/ {print $2}' $iniFile)

    docker stats $(docker ps --format '{{.Names}}' | grep ".*.$clusterName")
fi
