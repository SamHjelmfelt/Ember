#!/bin/bash

if [ $# -lt 1 ]
then
  echo "Number of worker nodes not specified - using a default of 4"
  NUM_WORKERS="4" 
else
  NUM_WORKERS=$1
fi

BLUEPRINT_BASE=$2
: ${BLUEPRINT_BASE:="multinode"}


#Start the Namenode/Ambari Server 
echo "Starting Namenode/Ambari Server..."
docker run --privileged=true -d --dns 8.8.8.8 -p 8080:8080 -p 8440:8440 -p 8441:8441 -p 50070:50070 -p 8020:8020 -e AMBARI_SERVER=namenode -e BLUEPRINT_BASE=${BLUEPRINT_BASE} --name namenode -h namenode -i -t hwxu/ambari_2.2_server_node
IP_namenode=$(docker inspect --format "{{ .NetworkSettings.IPAddress }}" namenode)
echo "Namenode/Ambari Server started at $IP_namenode"

#Start the ResourceManager
echo "Starting ResourceManager..."
docker run --privileged=true -d --link namenode:namenode -e namenode_ip=$IP_namenode -e AMBARI_SERVER=namenode --dns 8.8.8.8 -p 8088:8088 -p 8032:8032 -p 50060:50060 -p 8081:8081 -p 8030:8030 -p 8050:8050 -p 8025:8025 -p 8141 -p 8440 -p 8441 -p 19888:19888 -p 45454 -p 10020:10020 -p 22 --name resourcemanager -h resourcemanager -i -t hwxu/ambari_2.2_agent_node
IP_resourcemanager=$(docker inspect --format "{{ .NetworkSettings.IPAddress }}" resourcemanager)
echo "ResourceManager running on $IP_resourcemanager"

#Start the Hive/Oozie Server
echo "Starting a Hive/Oozie server..."
docker run --privileged=true -d --link namenode:namenode -e namenode_ip=$IP_namenode -e AMBARI_SERVER=namenode --dns 8.8.8.8 -p 11000:11000 -p 2181 -p 50111:50111 -p 9083 -p 10000 -p 9999:9999 -p 9933:9933 -p 22 -p 8440 -p 8441 --name hiveserver -h hiveserver -i -t hwxu/ambari_2.2_agent_node
IP_hive=$(docker inspect --format "{{ .NetworkSettings.IPAddress }}" hiveserver)
echo "Hive/Oozie running on $IP_hive"

#Start the worker nodes
echo "Starting $NUM_WORKERS worker nodes..."
for (( i=1; i<=$NUM_WORKERS; ++i));
do
nodename="node$i"
docker run --privileged=true -d --dns 8.8.8.8 -h $nodename --name $nodename -p 22 --link namenode:namenode -e AMBARI_SERVER=namenode -p 8440 -p 8441 -i -t hwxu/ambari_2.2_agent_node
IP_node=$(docker inspect --format "{{ .NetworkSettings.IPAddress }}" $nodename)
echo "Started worker $nodename on IP $IP_node"
done

