#!/bin/bash

cd ambari_2.2_node
docker build -t hwxu/ambari_2.2_node .

cd ../ambari_2.2_server_node
docker build -t hwxu/ambari_2.2_server_node .

cd ../ambari_2.2_agent_node
docker build -t hwxu/ambari_2.2_agent_node .

cd ..