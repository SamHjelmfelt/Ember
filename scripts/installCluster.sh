#!/bin/bash


if [[ -z $1 ]]; then
  echo "Usage: $0 <configuration.ini> "
  exit -1
fi

iniFile=$1

clusterName=$(awk -F "=" '/clusterName/ {print $2}' $iniFile)
hdpVersion=$(awk -F "=" '/hdpVersion/ {print $2}' $iniFile)
blueprintName=$(awk -F "=" '/blueprintName/ {print $2}' $iniFile)
blueprintFile=$(awk -F "=" '/blueprintFile/ {print $2}' $iniFile)
blueprintHostMappingFile=$(awk -F "=" '/blueprintHostMappingFile/ {print $2}' $iniFile)
ambariServerContainerName="$(awk -F "=" '/ambariServerHostName/ {print $2}' $iniFile).$clusterName"
ambariServerInternalIP=$(docker inspect --format "{{ .NetworkSettings.Networks.$clusterName.IPAddress }}" $ambariServerContainerName)
repoIP=$(docker inspect --format "{{ .NetworkSettings.Networks.repoNet.IPAddress }}" "reponode_${hdpVersion//./-}")


hdpUtilsVersion=$(curl "http://$repoIP/hdp/"  &> /dev/stdout | egrep -o 'HDP-UTILS-[\.0-9]*' | head -n1 | cut -c11-)

stackversion=${hdpVersion:0:3}
echo $stackversion


curl --user admin:admin -H 'X-Requested-By:DockerDoop' -X PUT http://$ambariServerInternalIP:8080/api/v1/stacks/HDP/versions/$stackversion/operating_systems/redhat7/repositories/HDP-$stackversion \
        -d "{\"Repositories\":{\"base_url\":\"http://$repoIP/hdp/HDP-$hdpVersion/\",\"verify_base_url\":true}}"
curl --user admin:admin -H 'X-Requested-By:DockerDoop' -X PUT http://$ambariServerInternalIP:8080/api/v1/stacks/HDP/versions/$stackversion/operating_systems/redhat7/repositories/HDP-UTILS-$hdpUtilsVersion \
        -d "{\"Repositories\":{\"base_url\":\"http://$repoIP/hdp/HDP-UTILS-$hdpUtilsVersion/\",\"verify_base_url\":true}}"

blueprintContent=`cat $blueprintFile `; echo
curl --user admin:admin -H 'X-Requested-By:DockerDoop' -X POST http://$ambariServerInternalIP:8080/api/v1/blueprints/$blueprintName -d "${blueprintContent/STACKVERSION/$stackversion}"
curl --user admin:admin -H 'X-Requested-By:DockerDoop' -X POST http://$ambariServerInternalIP:8080/api/v1/clusters/$clusterName -d @$blueprintHostMappingFile

echo ""
echo "HDP is currently installing"
echo "Run scripts/installStatus.sh or go to http://$ambariServerInternalIP:8080 to check progress"
