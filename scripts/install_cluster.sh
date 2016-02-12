#!/bin/bash


if [[ -z $3 ]]; then
  echo "Usage: $0 <Ambari Server> <Cluster Name> <blueprint name>"
  exit -1
fi

ambariServer="$1"
clusterName="$2"
BLUEPRINT_BASE="$3"

curl --user admin:admin -H 'X-Requested-By:HortonworksUniversity' -X PUT http://$ambariServer:8080/api/v1/stacks/HDP/versions/2.2/operating_systems/redhat6/repositories/HDP-2.2 \
        -d "{\"Repositories\":{\"base_url\":\"http://$ambariServer/hdp/HDP-2.3.4.0\",\"verify_base_url\":true}}"
curl --user admin:admin -H 'X-Requested-By:HortonworksUniverity' -X PUT http://$ambariServer:8080/api/v1/stacks/HDP/versions/2.2/operating_systems/redhat6/repositories/HDP-UTILS-1.1.0.20 \
        -d "{\"Repositories\":{\"base_url\":\"http://$ambariServer/hdp/HDP-UTILS-1.1.0.20\",\"verify_base_url\":true}}"



blueprintHostMapping=(blueprints/${BLUEPRINT_BASE}/*.hostmapping)
blueprintBlueprint=(blueprints/${BLUEPRINT_BASE}/*.blueprint)
curl --user admin:admin -H 'X-Requested-By:HortonworksUniverity' -X POST http://$ambariServer:8080/api/v1/blueprints/$BLUEPRINT_BASE -d @${blueprintBlueprint[0]}
curl --user admin:admin -H 'X-Requested-By:HortonworksUniversity' -X POST http://$ambariServer:8080/api/v1/clusters/$clusterName -d @${blueprintHostMapping[0]}

echo ""
echo "HDP is currently installing - run scripts/install_status.sh to check progress..."
