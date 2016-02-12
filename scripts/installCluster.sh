#!/bin/bash


if [[ -z $1 ]]; then
  echo "Usage: $0 <configuration.ini> "
  exit -1
fi

iniFile=$1

clusterName=$(awk -F "=" '/clusterName/ {print $2}' $iniFile)
blueprint=$(awk -F "=" '/blueprint/ {print $2}' $iniFile)
ambariServerContainerName="$(awk -F "=" '/ambariServer/ {print $2}' $iniFile).$clusterName"
ambariServerInternalIP=$(docker inspect --format "{{ .NetworkSettings.Networks.$clusterName.IPAddress }}" $ambariServerContainerName)

curl --user admin:admin -H 'X-Requested-By:HortonworksUniversity' -X PUT http://$ambariServerInternalIP:8080/api/v1/stacks/HDP/versions/2.3/operating_systems/redhat6/repositories/HDP-2.3 \
        -d "{\"Repositories\":{\"base_url\":\"http://$ambariServerInternalIP/hdp/HDP-2.3.4.0/\",\"verify_base_url\":true}}"
curl --user admin:admin -H 'X-Requested-By:HortonworksUniverity' -X PUT http://$ambariServerInternalIP:8080/api/v1/stacks/HDP/versions/2.3/operating_systems/redhat6/repositories/HDP-UTILS-1.1.0.20 \
        -d "{\"Repositories\":{\"base_url\":\"http://$ambariServerInternalIP/hdp/HDP-UTILS-1.1.0.20/\",\"verify_base_url\":true}}"



blueprintHostMapping=(blueprints/${blueprint}/*.hostmapping)
blueprintBlueprint=(blueprints/${blueprint}/*.blueprint)
curl --user admin:admin -H 'X-Requested-By:HortonworksUniverity' -X POST http://$ambariServerInternalIP:8080/api/v1/blueprints/$blueprint -d @${blueprintBlueprint[0]}
curl --user admin:admin -H 'X-Requested-By:HortonworksUniversity' -X POST http://$ambariServerInternalIP:8080/api/v1/clusters/$clusterName -d @${blueprintHostMapping[0]}

echo ""
echo "HDP is currently installing - run scripts/install_status.sh to check progress..."
