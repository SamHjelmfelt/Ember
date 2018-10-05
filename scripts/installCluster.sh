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
baseVersion=${hdpVersion:0:7}
echo $stackversion

#Put Repos
wget http://public-repo-1.hortonworks.com/HDP/centos7/2.x/updates/$baseVersion/HDP-${hdpVersion}.xml -O HDP-${hdpVersion}.xml
sed -i "s#http://public-repo-1.hortonworks.com/HDP/centos7/2.x/updates/$baseVersion#http://$repoIP/hdp/HDP-$baseVersion/#g" HDP-${hdpVersion}.xml
sed -i "s#http://public-repo-1.hortonworks.com/HDP-GPL/centos7/2.x/updates/$baseVersion#http://$repoIP/hdp/HDP-GPL-$baseVersion/#g" HDP-${hdpVersion}.xml
sed -i "s#http://public-repo-1.hortonworks.com/HDP-UTILS-$hdpUtilsVersion/repos/centos7#http://$repoIP/hdp/HDP-UTILS-$hdpUtilsVersion/#g" HDP-${hdpVersion}.xml

docker cp HDP-${hdpVersion}.xml $ambariServerContainerName:/version_definitions_HDP-${hdpVersion}.xml

curl --user admin:admin -H 'X-Requested-By:DockerDoop' -X POST http://$ambariServerInternalIP:8080/api/v1/version_definitions \
        -d "{ \"VersionDefinition\": { \"version_url\": \"file:/version_definitions_HDP-${hdpVersion}.xml\" } }"

#Put blueprint
blueprintContent=`cat $blueprintFile | sed "s/STACKVERSION/$stackversion/g"`; #echo $blueprintContent;
curl --user admin:admin -H 'X-Requested-By:DockerDoop' -X POST http://$ambariServerInternalIP:8080/api/v1/blueprints/$blueprintName -d "${blueprintContent}"

#Install cluster
hostMappingContent=`cat $blueprintHostMappingFile | sed "s/REPOSITORYVERSION/$hdpVersion/g"`;
curl --user admin:admin -H 'X-Requested-By:DockerDoop' -X POST http://$ambariServerInternalIP:8080/api/v1/clusters/$clusterName -d "${hostMappingContent}"

echo ""
echo "HDP is currently installing"
echo "Run scripts/installStatus.sh or go to http://$ambariServerInternalIP:8080 to check progress"
