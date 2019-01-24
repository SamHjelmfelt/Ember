#!/bin/bash

sed -i "s/localhost/$MASTER_SERVER/g" /etc/ambari-agent/conf/ambari-agent.ini

ambari-agent start
