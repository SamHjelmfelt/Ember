#!/bin/bash

sed -i "s/server_host=localhost/server_host=$MASTER_SERVER/g" /etc/cloudera-scm-agent/config.ini

service cloudera-scm-agent start
