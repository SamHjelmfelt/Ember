#!/bin/bash

if [[ -z $1 ]]; then
  echo "Usage: $0 <configuration.ini> "
  exit -1
fi

iniFile=$1

clusterName=$(awk -F "=" '/clusterName/ {print $2}' $iniFile)
ambariServerContainerName="$(awk -F "=" '/ambariServerHostName/ {print $2}' $iniFile).$clusterName"
ambariServerInternalIP=$(docker inspect --format "{{ .NetworkSettings.Networks.$clusterName.IPAddress }}" $ambariServerContainerName)


curl -u admin:admin -L http://$ambariServerInternalIP:8080/api/v1/clusters/$clusterName?format=blueprint
