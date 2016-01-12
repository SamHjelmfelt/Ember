#!/bin/bash

if [[ -z $1 ]]; then
  echo "Usage: $0 <blueprint base name>"  
  exit -1
fi

BLUEPRINT_BASE=$1

curl --user admin:admin -H 'X-Requested-By:HortonworksUniverity' -X PUT http://localhost:8080/api/v1/stacks/HDP/versions/2.2/operating_systems/redhat6/repositories/HDP-2.2 -d @/root/repos/hdp.repo

curl --user admin:admin -H 'X-Requested-By:HortonworksUniverity' -X PUT http://localhost:8080/api/v1/stacks/HDP/versions/2.2/operating_systems/redhat6/repositories/HDP-UTILS-1.1.0.20 -d @/root/repos/hdputils.repo

curl --user admin:admin -H 'X-Requested-By:HortonworksUniverity' -X POST http://localhost:8080/api/v1/blueprints/$BLUEPRINT_BASE -d @/root/blueprints/${BLUEPRINT_BASE}.blueprint
curl --user admin:admin -H 'X-Requested-By:HortonworksUniversity' -X POST http://localhost:8080/api/v1/clusters/$BLUEPRINT_BASE -d @/root/blueprints/${BLUEPRINT_BASE}.hostmapping

echo ""
echo "HDP is currently installing - run /root/scripts/install_status.sh to check progress..."
