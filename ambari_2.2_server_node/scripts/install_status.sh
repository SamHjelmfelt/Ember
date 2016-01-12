#!/bin/bash

if [[ -z $1 ]]; then
  echo "Usage: $0 <blueprint base name>"
  exit -1
fi

BLUEPRINT_BASE=$1

curl -s --user admin:admin -H 'X-Requested-By:HortonworksUniverity' http://localhost:8080/api/v1/clusters/$BLUEPRINT_BASE/requests/1 | grep request_status | grep IN_PROGRESS > /dev/null

if [[ $? == 0 ]]; then
  echo "Cluster is still installing..."
  curl -s --user admin:admin -H 'X-Requested-By:HortonworksUniverity' http://localhost:8080/api/v1/clusters/$BLUEPRINT_BASE/requests/1 | grep progress_percent
  exit 0
fi

curl -s --user admin:admin -H 'X-Requested-By:HortonworksUniverity' http://localhost:8080/api/v1/clusters/$BLUEPRINT_BASE/requests/1 | grep request_status
exit 1

