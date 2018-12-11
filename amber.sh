#!/bin/bash

ports=(22 2181 3000 3372 3373 4040 6627 6700 6701 6702 6703 8010 8020 8025 8030 8032 8050 8080 53 8081 8088 8042 8141 9000 9080 9081 9082 9083 9084 9085 9086 9087 9999 9933 10000 10020 11000 18080 19888 45454 50010 50020 50060 50070 50075 50090 50111)
hdf_ports=(9090 61080 6667 8744 8000 7788)
networkName="amber"

if [[ -z $2 ]]; then
  echo "Usage: $0 $1 <configuration.ini> "
  exit -1
fi
iniFile=$2

clusterName=$(awk -F "=" '/clusterName/ {print $2}' $iniFile)
blueprint=$(awk -F "=" '/blueprint/ {print $2}' $iniFile)
hostNames=$(awk -F "=" '/hostNames/ {print $2}' $iniFile)
ambariVersion=$(awk -F "=" '/ambariVersion/ {print $2}' $iniFile)
hdpVersion=$(awk -F "=" '/hdpVersion/ {print $2}' $iniFile)
blueprintName=$(awk -F "=" '/blueprintName/ {print $2}' $iniFile)
blueprintFile=$(awk -F "=" '/blueprintFile/ {print $2}' $iniFile)
blueprintHostMappingFile=$(awk -F "=" '/blueprintHostMappingFile/ {print $2}' $iniFile)
mPacks=$(awk -F "=" '/mPacks/ {print $2}' $iniFile)
buildRepo=$(awk -F "=" '/buildRepo/ {print $2}' $iniFile)
ambariServerHostName=$(awk -F "=" '/ambariServerHostName/ {print $2}' $iniFile).$clusterName
ambariServerInternalIP=$(docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $ambariServerHostName 2> /dev/null)

repoNodeContainerName="amber_repo_node_$hdpVersion"
repoNodeImageName="samhjelmfelt/amber_repo_node:$hdpVersion"
serverImageName="samhjelmfelt/amber_server_node:$ambariVersion"
agentImageName="samhjelmfelt/amber_agent_node:$ambariVersion"

function pullImages(){
    docker network ls | grep $networkName
    if [ $? -ne 0 ]; then
      docker network create $networkName
      echo "Created $networkName network"
    fi

    if [ -z $buildRepo ]; then
      echo "Not pulling local repo"
    else
      echo "Pulling and starting local repo for HDP $hdpVersion"
      docker pull $repoNodeImageName
      docker run --privileged=true \
                  --security-opt seccomp:unconfined \
                  --cap-add=SYS_ADMIN \
                  --dns 8.8.8.8 \
                  --name $repoNodeContainerName \
                  -h $repoNodeContainerName \
                  --net $networkName \
                  --restart unless-stopped \
                  -itd \
                  $repoNodeImageName  \
          ||
      docker start $repoNodeContainerName
      docker network connect bridge $repoNodeContainerName
    fi
    docker pull $agentImageName
    docker pull $serverImageName
}
function buildImages(){

    if [ -z $buildRepo ]; then
      echo "Not creating local repo"
    else
      echo "Creating local repo for HDP $hdpVersion"
      docker build \
                  --build-arg hdpVersion=$hdpVersion \
                  -t $repoNodeImageName \
                  images/repo_node

      docker network ls | grep $networkName
      if [ $? -ne 0 ]; then
        docker network create $networkName
        echo "Created $networkName network"
      fi
      docker run --privileged=true \
                  --security-opt seccomp:unconfined \
                  --cap-add=SYS_ADMIN \
                  --dns 8.8.8.8 \
                  --name $repoNodeContainerName \
                  -h $repoNodeContainerName \
                  --net $networkName \
                  --restart unless-stopped \
                  -itd \
                  $repoNodeImageName  \
          ||
      docker start $repoNodeContainerName
      docker network connect bridge $repoNodeContainerName
    fi

    echo "Creating Ambari $ambariVersion images"
    docker build --build-arg ambariVersion=$ambariVersion -t $agentImageName images/ambari_agent_node
    docker build --build-arg ambariVersion=$ambariVersion -t $serverImageName --build-arg mPacks="$mPacks" images/ambari_server_node
}
function createNode(){
    nodeName="$1"
    externalIP="$2"
    portParams=""

    if [[ -n $externalIP ]]; then
        for i in ${ports[@]}; do
            portParams="$portParams -p $externalIP:$i:$i"
        done
        for i in ${hdf_ports[@]}; do
            portParams="$portParams -p $externalIP:$i:$i"
        done
    fi

    docker network ls | grep $networkName
    if [ $? -ne 0 ]; then
        docker network create $networkName
        echo "Created $networkName network"
    fi

    containerName="$nodeName.$clusterName"
    imageName=""
    YARN_DNS_IP=""

    if [ $containerName != $ambariServerHostName ]; then
        echo "Creating Ambari agent node: $nodeName. Ambari server: $ambariServerHostName"
        imageName=$agentImageName
        YARN_DNS_IP=$ambariServerInternalIP
    else
        echo "Creating Ambari server node: $nodeName"
        imageName=$serverImageName
        YARN_DNS_IP=127.0.0.1
    fi

    docker run --privileged \
                --stop-signal=RTMIN+3 \
                --restart unless-stopped \
                $portParams \
                --net $networkName \
                --dns=8.8.8.8 \
                --dns=$YARN_DNS_IP \
                --name $containerName \
                -h $containerName \
                -e AMBARI_SERVER=$ambariServerHostName \
                -e DOCKER_HOST=unix:///host/var/run/docker.sock \
                -v "/var/run/docker.sock:/host/var/run/docker.sock" \
                -v "/var/lib/docker/containers:/containers" \
                -v "/sys/fs/cgroup:/sys/fs/cgroup" \
                -idt \
                $imageName

    docker exec -i -t $containerName /root/startup.sh

    internalIP=$(docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $containerName)
    if [[ -n $externalIP ]]; then
        echo "$nodeName started. Internal IP = $internalIP, External IP = $externalIP, Cluster = $clusterName"
    else
        echo "$nodeName started. Internal IP = $internalIP, Cluster = $clusterName"
    fi
}
function createCluster(){
    hostNameArr=(${hostNames//,/ })
    len=${#hostNameArr[@]}

    if grep -q "externalIPs" $iniFile ; then

        externalIPs=$(awk -F "=" '/externalIPs/ {print $2}' $iniFile)
        externalIpsArr=(${externalIPs//,/ })

        if [ ${#hostNameArr[@]} -ne ${#externalIpsArr[@]} ]; then
            echo "The number of host names defined do not match the number of IPs defined!"
            exit 1
        fi

        for i in $(seq 0 $(($len-1)));
        do
          createNode ${hostNameArr[$i]} ${externalIpsArr[$i]}
        done
    else
        for i in $(seq 0 $(($len-1)));
        do
          createNode ${hostNameArr[$i]}
        done
    fi
}
function exportBlueprint(){
    curl -u admin:admin -L http://$ambariServerInternalIP:8080/api/v1/clusters/$clusterName?format=blueprint
}
function installCluster(){
    repoIP=$(docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $repoNodeContainerName)

    hdpUtilsVersion=$(curl "http://$repoIP/hdp/"  &> /dev/stdout | egrep -o 'HDP-UTILS-[\.0-9]*' | head -n1 | cut -c11-)

    baseVersion=${hdpVersion:0:7}
    stackversion=${hdpVersion:0:3}
    majorversion=${hdpVersion:0:1}

    #Put Repos
    wget http://public-repo-1.hortonworks.com/HDP/centos7/${majorversion}.x/updates/$baseVersion/HDP-${hdpVersion}.xml -O HDP-${hdpVersion}.xml
    sed -i "s#http://public-repo-1.hortonworks.com/HDP/centos7/${majorversion}.x/updates/$baseVersion#http://$repoIP/hdp/HDP-$baseVersion/#g" HDP-${hdpVersion}.xml
    sed -i "s#http://public-repo-1.hortonworks.com/HDP-GPL/centos7/${majorversion}.x/updates/$baseVersion#http://$repoIP/hdp/HDP-GPL-$baseVersion/#g" HDP-${hdpVersion}.xml
    sed -i "s#http://public-repo-1.hortonworks.com/HDP-UTILS-$hdpUtilsVersion/repos/centos7#http://$repoIP/hdp/HDP-UTILS-$hdpUtilsVersion/#g" HDP-${hdpVersion}.xml

    docker cp HDP-${hdpVersion}.xml $ambariServerHostName:/version_definitions_HDP-${hdpVersion}.xml

    curl --user admin:admin -H 'X-Requested-By:Amber' -X POST http://$ambariServerInternalIP:8080/api/v1/version_definitions \
            -d "{ \"VersionDefinition\": { \"version_url\": \"file:/version_definitions_HDP-${hdpVersion}.xml\" } }"

    #Put blueprint
    blueprintContent=`cat $blueprintFile | sed "s/STACKVERSION/$stackversion/g"`; #echo $blueprintContent;
    curl --user admin:admin -H 'X-Requested-By:Amber' -X POST http://$ambariServerInternalIP:8080/api/v1/blueprints/$blueprintName -d "${blueprintContent}"

    #Install cluster
    hostMappingContent=`cat $blueprintHostMappingFile | sed "s/REPOSITORYVERSION/$hdpVersion/g"`;
    curl --user admin:admin -H 'X-Requested-By:Amber' -X POST http://$ambariServerInternalIP:8080/api/v1/clusters/$clusterName -d "${hostMappingContent}"

    echo ""
    echo "Cluster is currently installing"
    echo "Run scripts/installStatus.sh or go to http://$ambariServerInternalIP:8080 to check progress"
}
function installStatus(){
    while true
    do
        curl -s --user admin:admin -H 'X-Requested-By:Amber' http://$ambariServerInternalIP:8080/api/v1/clusters/$clusterName/requests/1 | grep request_status | grep IN_PROGRESS > /dev/null

        if [[ $? == 0 ]]; then
          #echo "Cluster is still installing..."
          curl -s --user admin:admin -H 'X-Requested-By:Amber' http://$ambariServerInternalIP:8080/api/v1/clusters/$clusterName/requests/1 | grep progress_percent
          #exit 0
        else
            curl -s --user admin:admin -H 'X-Requested-By:Amber' http://$ambariServerInternalIP:8080/api/v1/clusters/$clusterName/requests/1 | grep request_status
            exit 1
        fi

        sleep 60
    done
}
function destroyCluster(){
    docker kill $(docker ps -a | grep ".*.$clusterName" | cut -f1 -d" ")
    docker rm -f $(docker ps -a | grep ".*.$clusterName" | cut -f1 -d" ")
}
function stats(){
    docker stats $(docker ps --format '{{.Names}}' | grep ".*.$clusterName")
}
function createFromPrebuiltSample(){

    if [ $clusterName != "yarnquickstart" ]; then
        echo "Only yarnquickstart is supported at this time"
    fi
    imageName="samhjelmfelt/amber_yarnquickstart:$hdpVersion"

    ports=$1

    docker pull $agentImageName
    docker pull $serverImageName
    docker pull $imageName
    
    docker network ls | grep $networkName
    if [ $? -ne 0 ]; then
        docker network create $networkName
        echo "Created $networkName network"
    fi

    docker run \
            --privileged \
            --restart unless-stopped \
            --net $networkName \
            --name $ambariServerHostName \
            --hostname $ambariServerHostName \
            -e DOCKER_HOST=unix:///host/var/run/docker.sock \
            -v "/var/run/docker.sock:/host/var/run/docker.sock" \
            -v "/var/lib/docker/containers:/containers" \
            -v "/sys/fs/cgroup:/sys/fs/cgroup" \
            $ports \
            -d \
            $imageName

    internalIP=$(docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $ambariServerHostName)

    echo "Starting Ambari..."
    docker exec -it $ambariServerHostName bash -c "ambari-server start; ambari-agent start"

    echo "Starting all services..."
    curl -i -u admin:admin -H "X-Requested-By: amber"  -X PUT  \
        -d '{"RequestInfo":{"context":"_PARSE_.START.ALL_SERVICES","operation_level":{"level":"CLUSTER","cluster_name":"'$clusterName'"}},"Body":{"ServiceInfo":{"state":"STARTED"}}}' \
        "http://$internalIP:8080/api/v1/clusters/$clusterName/services"
}

case "$1" in
  pullImages)
      pullImages
      ;;
  buildImages)
      buildImages
      ;;
  createCluster)
      createCluster
      ;;
  createNode)
      createNode $3 $4
      ;;
  exportBlueprint)
      exportBlueprint
      ;;
  installCluster)
      installCluster
      ;;
  installStatus)
      installStatus
      ;;
  destroyCluster)
      destroyCluster
      ;;
  stats)
      stats
      ;;
  createFromPrebuiltSample)
      createFromPrebuiltSample "$3"
      ;;
  *)
      echo "Usage:"
      echo "  $0 pullImages      <configuration.ini>"
      echo "  $0 buildImages     <configuration.ini>"
      echo "  $0 createCluster   <configuration.ini>"
      echo "  $0 createNode      <configuration.ini> <nodeName> [<external IP>]"
      echo "  $0 exportBlueprint <configuration.ini>"
      echo "  $0 installCluster  <configuration.ini>"
      echo "  $0 installStatus   <configuration.ini>"
      echo "  $0 destroyCluster  <configuration.ini>"
      echo "  $0 stats           <configuration.ini>"
      echo "  $0 createFromPrebuiltSample <configuration.ini> [<docker port options>]"
      ;;
esac