#!/bin/bash


if [[ -z $1 ]]; then
  echo "Usage: $0 <configuration.ini> "
  exit -1
fi

iniFile=$1

clusterName=$(awk -F "=" '/clusterName/ {print $2}' $iniFile)
blueprintName=$(awk -F "=" '/blueprintName/ {print $2}' $iniFile)
blueprintFile=$(awk -F "=" '/blueprintFile/ {print $2}' $iniFile)
blueprintHostMappingFile=$(awk -F "=" '/blueprintHostMappingFile/ {print $2}' $iniFile)
ambariServerContainerName="$(awk -F "=" '/ambariServerHostName/ {print $2}' $iniFile).$clusterName"
ambariServerInternalIP=$(docker inspect --format "{{ .NetworkSettings.Networks.$clusterName.IPAddress }}" $ambariServerContainerName)

curl --user admin:admin -H 'X-Requested-By:HortonworksUniversity' -X PUT http://$ambariServerInternalIP:8080/api/v1/stacks/HDP/versions/2.3/operating_systems/redhat6/repositories/HDP-2.3 \
        -d "{\"Repositories\":{\"base_url\":\"http://$ambariServerInternalIP/hdp/HDP-2.3.4.0/\",\"verify_base_url\":true}}"
curl --user admin:admin -H 'X-Requested-By:HortonworksUniverity' -X PUT http://$ambariServerInternalIP:8080/api/v1/stacks/HDP/versions/2.3/operating_systems/redhat6/repositories/HDP-UTILS-1.1.0.20 \
        -d "{\"Repositories\":{\"base_url\":\"http://$ambariServerInternalIP/hdp/HDP-UTILS-1.1.0.20/\",\"verify_base_url\":true}}"

curl --user admin:admin -H 'X-Requested-By:HortonworksUniverity' -X POST http://$ambariServerInternalIP:8080/api/v1/blueprints/$blueprintName -d @$blueprintFile
curl --user admin:admin -H 'X-Requested-By:HortonworksUniversity' -X POST http://$ambariServerInternalIP:8080/api/v1/clusters/$clusterName -d @$blueprintHostMappingFile

echo ""
echo "HDP is currently installing"
echo "Run scripts/installStatus.sh or go to http://$ambariServerInternalIP:8080 to check progress"
