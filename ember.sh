#!/bin/bash

all_ports=(2181 3000 3372 3373 4040 6627 6700 6701 6702 6703 8010 8020 8025 8030 8032 8050 8080 \
        53 8081 8088 8042 8141 9000 9080 9081 9082 9083 9084 9085 9086 9087 9999 9933 10000 10020 \
        11000 18080 19888 45454 50010 50020 50060 50070 50075 50090 50111 \
        9090 61080 6667 8744 8000 7788)
       

networkName="ember"

function printUsage() {
  echo "Usage:"
  echo "  $0 runRepo                  <configuration.ini>"
  echo "  $0 pullImages               <configuration.ini>"
  echo "  $0 buildImages              <configuration.ini>"
  echo "  $0 createCluster            <configuration.ini>"
  echo "  $0 createNode               <configuration.ini> <nodeName> [<external IP>]"
  echo "  $0 exportClusterDefinition  <configuration.ini>"
  echo "  $0 installCluster           <configuration.ini>"
  echo "  $0 installStatus            <configuration.ini>"
  echo "  $0 stopCluster              <configuration.ini>"
  echo "  $0 startCluster             <configuration.ini>"
  echo "  $0 removeCluster            <configuration.ini>"
  echo "  $0 stats                    <configuration.ini>"
  echo "  $0 createFromPrebuiltSample <configuration.ini>"
}

if [[ -z $2 ]]; then
  printUsage
  exit -1
fi
iniFile=$2

clusterName=$(awk -F "=" '/clusterName/ {print $2}' $iniFile)
blueprint=$(awk -F "=" '/blueprint/ {print $2}' $iniFile)
hostNames=$(awk -F "=" '/hostNames/ {print $2}' $iniFile)
managerVersion=$(awk -F "=" '/managerVersion/ {print $2}' $iniFile)
clusterVersion=$(awk -F "=" '/clusterVersion/ {print $2}' $iniFile)
templateFile=$(awk -F "=" '/templateFile/ {print $2}' $iniFile)
blueprintName=$(awk -F "=" '/blueprintName/ {print $2}' $iniFile)
blueprintFile=$(awk -F "=" '/blueprintFile/ {print $2}' $iniFile)
blueprintHostMappingFile=$(awk -F "=" '/blueprintHostMappingFile/ {print $2}' $iniFile)
mPacks=$(awk -F "=" '/mPacks/ {print $2}' $iniFile)
buildRepo=$(awk -F "=" '/buildRepo/ {print $2}' $iniFile)
managerServerHostName=$(awk -F "=" '/managerServerHostName/ {print $2}' $iniFile).$clusterName
managerServerInternalIP=$(docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $managerServerHostName 2> /dev/null)
portString=$(awk -F "=" '/ports/ {print $2}' $iniFile)
ambari=$(awk -F "=" '/ambari/ {print $2}' $iniFile)

if [ -z $portString ]; then
  ports=${all_ports[@]}
else
  ports=($(echo "$portString" | tr ',' '\n'))
fi

portParams=""
for i in ${ports[@]}; do
    if [[ "$i" =~ ^[0-9]+$ ]]; then
        portPair=$i:$i
    elif [[ "$i" =~ ^[0-9]+:[0-9]+$ ]]; then
        portPair=$i
    else
        echo "invalid port configuration"
        exit 1;
    fi
    if [[ -n $externalIP ]]; then
        portParams="$portParams -p $externalIP:$portPair"
    else
        portParams="$portParams -p $portPair"
    fi
done

if [ -z "$ambari" ]; then
    repoNodeContainerName="ember_cdh_repo_node_$clusterVersion"
    repoNodeImageName="samhjelmfelt/ember_cdh_repo_node:$clusterVersion"
    serverImageName="samhjelmfelt/ember_cm_server_node:$managerVersion"
    agentImageName="samhjelmfelt/ember_cm_agent_node:$managerVersion"
else
    repoNodeContainerName="ember_hdp_repo_node_$clusterVersion"
    repoNodeImageName="samhjelmfelt/ember_hdp_repo_node:$clusterVersion"
    serverImageName="samhjelmfelt/ember_ambari_server_node:$managerVersion"
    agentImageName="samhjelmfelt/ember_ambari_agent_node:$managerVersion"
fi
function runRepo(){
    if [ -z "$ambari" ]; then
        echo "Local repos are not supported for CM-based clusters at this time"
        exit 1;
    fi
    docker network ls | grep $networkName
    if [ $? -ne 0 ]; then
      docker network create $networkName
      echo "Created $networkName network"
    fi

    echo "Starting local repo for HDP $clusterVersion"
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
}

function pullImages(){
    docker network ls | grep $networkName
    if [ $? -ne 0 ]; then
      docker network create $networkName
      echo "Created $networkName network"
    fi

    if [ -z $buildRepo ]; then
      echo "Not pulling local repo"
    else
      if [ -z "$ambari" ]; then
          echo "Local repos are not supported for CM-based clusters at this time"
          exit 1;
      fi

      echo "Pulling local repo image for HDP $clusterVersion"
      docker pull $repoNodeImageName
      runRepo
    fi
    docker pull $agentImageName
    docker pull $serverImageName
}
function buildImages(){

    if [ -z $buildRepo ]; then
        echo "Not creating local repo"
    else
        if [ -z "$ambari" ]; then
            echo "Local repos are not supported for CM-based clusters at this time"
            exit 1;
        else
            echo "Creating local repo for HDP $clusterVersion"
            docker build \
                        --build-arg clusterVersion=$clusterVersion \
                        -t $repoNodeImageName \
                        images/hdp_repo_node
            runRepo
        fi
    fi

    if [ -z "$ambari" ]; then
        echo "Creating CM $managerVersion images"
        docker build --build-arg managerVersion=$managerVersion -t $agentImageName images/CM_agent_node
        docker build --build-arg managerVersion=$managerVersion -t $serverImageName --build-arg mPacks="$mPacks" images/CM_server_node
    else
        echo "Creating Ambari $managerVersion images"
        docker build --build-arg managerVersion=$managerVersion -t $agentImageName images/ambari_agent_node
        docker build --build-arg managerVersion=$managerVersion -t $serverImageName --build-arg mPacks="$mPacks" images/ambari_server_node
    fi
}
function createNode(){
    nodeName="$1"
    externalIP="$2"

    docker network ls | grep $networkName
    if [ $? -ne 0 ]; then
        docker network create $networkName
        echo "Created $networkName network"
    fi

    containerName="$nodeName.$clusterName"
    imageName=""
    YARN_DNS_IP=""

    if [ $containerName != $managerServerHostName ]; then
        echo "Creating agent node: $nodeName. Master server: $managerServerHostName"
        imageName=$agentImageName
        YARN_DNS_IP=$managerServerInternalIP
    else
        echo "Creating server node: $nodeName"
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
                -e MASTER_SERVER=$managerServerHostName \
                -e DOCKER_HOST=unix:///host/var/run/docker.sock \
                -v "/var/run/docker.sock:/host/var/run/docker.sock" \
                -v "/var/lib/docker/containers:/containers" \
                -v "/sys/fs/cgroup:/sys/fs/cgroup" \
                -idt \
                $imageName


    if [ ! -z "$ambari" ]; then
        if [ $containerName == $managerServerHostName ]; then
            for i in ${mPacks//,/ }; do
                if [ -n "$i" ]; then
                    docker exec -i -t $containerName ambari-server install-mpack --mpack=$i;
                fi;
            done
        fi
    fi
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
function exportClusterDefinition(){
    if [ -z "$ambari" ]; then
        curl -u admin:admin -L "http://$managerServerInternalIP:7180/api/v12/clusters/$clusterName/export"
    else
        curl -u admin:admin -L "http://$managerServerInternalIP:8080/api/v1/clusters/$clusterName?format=blueprint"
    fi
}
function installCluster(){
    repoIP=$(docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $repoNodeContainerName)

    baseVersion=${clusterVersion:0:7}
    stackversion=${clusterVersion:0:3}
    majorversion=${clusterVersion:0:1}


    if [ -z "$ambari" ]; then
        docker exec -it $managerServerHostName bash -c "curl -X POST -H 'Content-Type: application/json' -d '$(cat "$templateFile")' \
            http://admin:admin@localhost:7180/api/v12/cm/importClusterTemplate"
        port=7180
    else
        curl "http://public-repo-1.hortonworks.com/HDP/centos7/${majorversion}.x/updates/$baseVersion/HDP-${clusterVersion}.xml" \
            -o "HDP-${clusterVersion}.xml"

        if [ ! -z $repoIP ]; then
            sed -i "" "s#http://public-repo-1.hortonworks.com/HDP/centos7/${majorversion}.x/updates/$baseVersion#http://$repoIP/hdp/HDP-$baseVersion/#g" "HDP-${clusterVersion}.xml"
            sed -i "" "s#http://public-repo-1.hortonworks.com/HDP-GPL/centos7/${majorversion}.x/updates/$baseVersion#http://$repoIP/hdp/HDP-GPL-$baseVersion/#g" "HDP-${clusterVersion}.xml"
            sed -i "" "s#http://public-repo-1.hortonworks.com/HDP-UTILS-\([0-9\.]*\)/repos/centos7#http://$repoIP/hdp/HDP-UTILS-\1/#g" "HDP-${clusterVersion}.xml"
        fi

        docker cp HDP-${clusterVersion}.xml $managerServerHostName:/version_definitions_HDP-${clusterVersion}.xml

        docker exec -it $managerServerHostName bash -c "curl --user admin:admin -H 'X-Requested-By:Ember' -X POST http://localhost:8080/api/v1/version_definitions \
                -d \"{ \\\"VersionDefinition\\\": { \\\"version_url\\\": \\\"file:/version_definitions_HDP-${clusterVersion}.xml\\\" } }\""

        #Put blueprint
        blueprintContent=`cat $blueprintFile | sed "s/STACKVERSION/$stackversion/g"`;
        docker exec -it $managerServerHostName bash -c "curl --user admin:admin -H 'X-Requested-By:Ember' -X POST http://localhost:8080/api/v1/blueprints/$blueprintName -d '$blueprintContent'"

        #Install cluster
        hostMappingContent=`cat $blueprintHostMappingFile | sed "s/REPOSITORYVERSION/$clusterVersion/g"`;
        docker exec -it $managerServerHostName bash -c "curl --user admin:admin -H 'X-Requested-By:Ember' -X POST http://localhost:8080/api/v1/clusters/$clusterName -d '$hostMappingContent'"

        port=8080
    fi
    echo ""
    echo "Cluster is currently installing"
    echo "Run scripts/installStatus.sh or go to http://$managerServerInternalIP:$port to check progress"
}
function installStatus(){
    while true
    do
        curl -s --user admin:admin -H 'X-Requested-By:Ember' http://$managerServerInternalIP:8080/api/v1/clusters/$clusterName/requests/1 | grep request_status | grep IN_PROGRESS > /dev/null

        if [[ $? == 0 ]]; then
          #echo "Cluster is still installing..."
          curl -s --user admin:admin -H 'X-Requested-By:Ember' http://$managerServerInternalIP:8080/api/v1/clusters/$clusterName/requests/1 | grep progress_percent
          #exit 0
        else
            curl -s --user admin:admin -H 'X-Requested-By:Ember' http://$managerServerInternalIP:8080/api/v1/clusters/$clusterName/requests/1 | grep request_status
            exit 1
        fi

        sleep 60
    done
}
function removeCluster(){
    docker kill $(docker ps -a | grep ".*.$clusterName" | cut -f1 -d" ")
    docker rm -f $(docker ps -a | grep ".*.$clusterName" | cut -f1 -d" ")
}
function stopCluster(){
    docker stop $(docker ps -a | grep ".*.$clusterName" | cut -f1 -d" ")
}
function startCluster(){
    docker start $(docker ps -a | grep ".*.$clusterName" | cut -f1 -d" ")
    startClusterServices
}
function startClusterServices(){
    if [ -z "$ambari" ]; then
        echo "Starting Cloudera Manager..."
        docker exec -it $managerServerHostName bash -c "systemctl start cloudera-scm-server; systemctl start cloudera-scm-agent"

        echo "Starting all services"
        docker exec -it $managerServerHostName bash -c "curl -u admin:admin -X POST localhost:7180/api/v16/clusters/$clusterName/commands/start"
        echo "Starting all services. Visit http://localhost:7180 to view the status"
    else
        echo "Starting Ambari..."
        docker exec -it $managerServerHostName bash -c "ambari-server start; ambari-agent start"

        output=""
        echo "Waiting for agent heartbeat..."
        while [[ ${output} != *"Accepted"* ]]; do
            output=$(docker exec -it $managerServerHostName bash -c "curl -s -u admin:admin -H \"X-Requested-By: ember\"  -X PUT  \
                -d '{\"RequestInfo\":{\"context\":\"_PARSE_.START.ALL_SERVICES\",\"operation_level\":{\"level\":\"CLUSTER\",\"cluster_name\":\"'$clusterName'\"}},\"Body\":{\"ServiceInfo\":{\"state\":\"STARTED\"}}}' \
                \"http://localhost:8080/api/v1/clusters/$clusterName/services\"")

            sleep 1
        done
        echo "Starting all services. Visit http://localhost:8080 to view the status"
    fi

}

function stats(){
    docker stats $(docker ps --format '{{.Names}}' | grep ".*.$clusterName")
}
function createFromPrebuiltSample(){

    imageName="samhjelmfelt/ember_"$(echo "$clusterName" | awk '{print tolower($0)}')":$clusterVersion"

    docker pull $agentImageName
    docker pull $serverImageName
    docker pull $imageName

    docker network ls | grep $networkName
    if [ $? -ne 0 ]; then
        docker network create $networkName
        echo "Created $networkName network"
    fi
#--dns=127.0.0.1 \
    docker run \
            --privileged \
            --restart unless-stopped \
            --net $networkName \
            --dns=8.8.8.8 \
            --name $managerServerHostName \
            --hostname $managerServerHostName \
            -e DOCKER_HOST=unix:///host/var/run/docker.sock \
            -v "/var/run/docker.sock:/host/var/run/docker.sock" \
            -v "/var/lib/docker/containers:/containers" \
            -v "/sys/fs/cgroup:/sys/fs/cgroup" \
            $portParams \
            -d \
            $imageName

    startClusterServices
}

case "$1" in

  runRepo)
      runRepo
      ;;
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
  exportClusterDefinition)
      exportClusterDefinition
      ;;
  installCluster)
      installCluster
      ;;
  installStatus)
      installStatus
      ;;
  stopCluster)
      stopCluster
      ;;
  startCluster)
      startCluster
      ;;
  removeCluster)
      removeCluster
      ;;
  stats)
      stats
      ;;
  createFromPrebuiltSample)
      createFromPrebuiltSample
      ;;
  *)
      printUsage
      ;;
esac