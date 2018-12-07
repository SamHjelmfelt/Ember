#!/bin/bash

sed -i "s/localhost/$AMBARI_SERVER/g" /etc/ambari-agent/conf/ambari-agent.ini

ambari-agent start
