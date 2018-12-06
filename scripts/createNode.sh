#!/bin/bash


if [[ -z $4 ]]; then
  echo "Usage: $0 <ambariVersion> <node name> <ambariServerHostName> <clusterName>  [<externalIP>]"
  exit -1
fi

ambariVersion="$1"
nodeName="$2"
ambariServerHostName="$3"
clusterName="$4"

portParams=""

if [[ -n $5 ]]; then
    externalIP="$5"

    ports=(22 2181 3000 3372 3373 4040 6627 6700 6701 6702 6703 8010 8020 8025 8030 8032 8050 8080 8081 8088 8141 9000 9080 9081 9082 9083 9084 9085 9086 9087 9999 9933 10000 10020 11000 18080 19888 45454 50010 50020 50060 50070 50075 50090 50111)
    hdf_ports=(9090 61080 6667 8744 8000 7788)
    for i in ${ports[@]}; do
        portParams="$portParams -p $externalIP:$i:$i"
    done
    for i in ${hdf_ports[@]}; do
        portParams="$portParams -p $externalIP:$i:$i"
    done
fi

docker network ls | grep dockerdoop
if [ $? -ne 0 ]; then
    docker network create dockerdoop
    echo "Created network for DockerDoop"
fi

containerName="$nodeName.$clusterName"
imageName=""

if [ $containerName != $ambariServerHostName ]; then
    echo "Creating Ambari agent node: $nodeName. Ambari server: $ambariServerHostName"
    imageName='dockerdoop/ambari_agent_node_'$ambariVersion
else
    echo "Creating Ambari server node: $nodeName"
    imageName='dockerdoop/ambari_server_node_'$ambariVersion
fi

docker run --privileged \
            --stop-signal=RTMIN+3 \
            --restart unless-stopped \
            --dns 8.8.8.8 \
            $portParams \
            --net dockerdoop \
            --name $containerName \
            -h $containerName \
            --dns-search=$clusterName \
            -e AMBARI_SERVER=$ambariServerHostName \
            -e DOCKER_HOST=unix:///host/var/run/docker.sock \
            -v "/var/run/docker.sock:/host/var/run/docker.sock" \
            -v "/var/lib/docker/containers:/containers" \
            -v "/sys/fs/cgroup:/sys/fs/cgroup" \
            -idt \
            $imageName

docker exec -i -t $containerName /root/startup.sh

internalIP=$(docker inspect --format "{{ .NetworkSettings.Networks.dockerdoop.IPAddress }}" $containerName)


if [[ -n $4 ]]; then
    echo "$nodeName started. Internal IP = $internalIP, External IP = $5, Cluster = $clusterName"
else
    echo "$nodeName started. Internal IP = $internalIP, Cluster = $clusterName"
fi
