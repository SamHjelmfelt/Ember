#!/bin/bash

nodeName="$1"
ambariServer="$2"
prefix="$3"

if [ -n "$prefix" ]; then
    nodeName="$prefix-$nodeName"
    ambariServer="$prefix-$ambariServer"
fi

if [ $nodeName != $ambariServer ]; then
    echo "Creating Ambari agent node: $nodeName. Ambari server: $ambariServer"

    docker run --privileged=true \
                -d \
                --dns 8.8.8.8 \
                -p 22  -p 8440 -p 8441 \
                -e AMBARI_SERVER=$ambariServer \
                --name $nodeName \
                -h $nodeName \
                --link $ambariServer:$ambariServer \
                -i \
                -t hwxu/ambari_2.2_agent_node

    IP=$(docker inspect --format "{{ .NetworkSettings.IPAddress }}" $nodeName)
    echo "$nodeName started at $IP"

else
    echo "Creating Ambari server node: $nodeName"

    docker run --privileged=true \
                -d \
                --dns 8.8.8.8 \
                -p 8080:8080 -p 8440:8440 -p 8441:8441 -p 50070:50070 -p 8020:8020 \
                -e AMBARI_SERVER=$ambariServer \
                --name $nodeName \
                -h $nodeName \
                -i \
                -t hwxu/ambari_2.2_server_node

    IP=$(docker inspect --format "{{ .NetworkSettings.IPAddress }}" $nodeName)
    echo "$nodeName started at $IP"
fi