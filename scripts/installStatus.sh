#!/bin/bash

if [[ -z $1 ]]; then
  echo "Usage: $0 <configuration.ini> "
  exit -1
fi

iniFile=$1

clusterName=$(awk -F "=" '/clusterName/ {print $2}' $iniFile)
ambariServerContainerName="$(awk -F "=" '/ambariServer/ {print $2}' $iniFile).$clusterName"
ambariServerInternalIP=$(docker inspect --format "{{ .NetworkSettings.Networks.$clusterName.IPAddress }}" $ambariServerContainerName)


while true
do
    curl -s --user admin:admin -H 'X-Requested-By:HortonworksUniverity' http://$ambariServerInternalIP:8080/api/v1/clusters/$clusterName/requests/1 | grep request_status | grep IN_PROGRESS > /dev/null

    if [[ $? == 0 ]]; then
      #echo "Cluster is still installing..."
      curl -s --user admin:admin -H 'X-Requested-By:HortonworksUniverity' http://$ambariServerInternalIP:8080/api/v1/clusters/$clusterName/requests/1 | grep progress_percent
      #exit 0
    else
        curl -s --user admin:admin -H 'X-Requested-By:HortonworksUniverity' http://$ambariServerInternalIP:8080/api/v1/clusters/$clusterName/requests/1 | grep request_status
        exit 1
    fi

    sleep 60
done

