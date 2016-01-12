#!/bin/bash

#Wait a bit to ensure that Ambari server is fully up and running
sleep 20 

#I am commenting this out so that the blueprints don't install. I want to do a wizard install
/root/scripts/install_cluster.sh $BLUEPRINT_BASE

