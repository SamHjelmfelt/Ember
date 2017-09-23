#!/bin/bash


if [[ $1 = "--noRepo" ]]; then
  echo "Not creating local repo"
else
  #cd repo_node
  docker build -t hwxu/repo_node repo_node
  docker network create repoNet
  docker run --privileged=true \
              --security-opt seccomp:unconfined \
              --cap-add=SYS_ADMIN \
              -d \
              --dns 8.8.8.8 \
              --name reponode \
              -h reponode \
              --net repoNet \
              --restart unless-stopped \
              -i \
              -t hwxu/repo_node  \
              ||
  docker start reponode
   docker network connect bridge reponode

              #--net $clusterName \
              #--dns-search=$clusterName \
              #-p 172.16.96.136:80:80 \

  #cd ..
  internalIP=$(docker inspect --format "{{ .NetworkSettings.Networks.bridge.IPAddress }}" reponode)

  echo $internalIP
fi

cd ambari_2.4_node
docker build --build-arg ambariRepo=$internalIP/hdp/Updates-ambari-2.4.0.1/ -t hwxu/ambari_2.4_node .

cd ../ambari_2.4_server_node
docker build -t hwxu/ambari_2.4_server_node .

cd ../ambari_2.4_agent_node
docker build -t hwxu/ambari_2.4_agent_node .

cd ..