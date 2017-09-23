#!/bin/bash

if [[ -z $3 ]]; then
  echo "Usage: $0 <node name> <ambariServerHostName> <clusterName>  [<externalIP>]"
  exit -1
fi

nodeName="$1"
ambariServerHostName="$2"
clusterName="$3"

portParams=""

if [[ -n $4 ]]; then
    externalIP="$4"

    ports=(22 2181 3372 3373 6627 6667 6700 6701 6702 6703 8000 8010 8020 8025 8030 8032 8050 8080 8081 8088 8141 8744 9000 9080 9081 9082 9083 9084 9085 9086 9087 9999 9933 10000 10020 11000 19888 45454 50010 50020 50060 50070 50075 50090 50111)
    for i in ${ports[@]}; do
        portParams="$portParams -p $externalIP:$i:$i"
    done
fi


docker network ls | grep -q $clusterName
if [ $? -ne 0 ]; then
    docker network create $clusterName
    echo "Created network for $clusterName"
fi

containerName="$nodeName.$clusterName"

if [ $nodeName != $ambariServerHostName ]; then
    echo "Creating Ambari agent node: $nodeName. Ambari server: $ambariServerHostName"

    docker run --privileged \
                --stop-signal=SIGRTMIN+3 \
                -d \
                --dns 8.8.8.8 \
                $portParams \
                -e AMBARI_SERVER=$ambariServerHostName \
                --name $containerName \
                -h $nodeName \
                --net $clusterName \
                --dns-search=$clusterName \
                --restart unless-stopped \
                -i \
                -t hwxu/ambari_2.4_agent_node #\
                #/root/scripts/startup.sh
                # --security-opt seccomp:unconfined \
    docker network connect repoNet $containerName
    docker exec -i -t $containerName /root/scripts/startup.sh
else
    echo "Creating Ambari server node: $nodeName"

    docker run --privileged \
                --stop-signal=RTMIN+3 \
                -d \
                --dns 8.8.8.8 \
                $portParams \
                -e AMBARI_SERVER=$ambariServerHostName \
                --name $containerName \
                -h $nodeName \
                --net $clusterName \
                --dns-search=$clusterName \
                -i \
                -t hwxu/ambari_2.4_server_node #\
                #/root/scripts/startup.sh
                # --security-opt seccomp:unconfined \

                #--restart unless-stopped \



                #-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
                #
    docker network connect repoNet $containerName

    echo "Setting up Ambari"
    docker exec -i -t $containerName /root/scripts/startup.sh
fi

internalIP=$(docker inspect --format "{{ .NetworkSettings.Networks.$clusterName.IPAddress }}" $containerName)


if [[ -n $4 ]]; then
    echo "$nodeName started. Internal IP = $internalIP, External IP = $4, Cluster = $clusterName"
else
    echo "$nodeName started. Internal IP = $internalIP, Cluster = $clusterName"
fi