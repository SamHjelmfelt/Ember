#!/bin/bash

sed -i "s/server_host=localhost/server_host=$MASTER_SERVER/g" /etc/cloudera-scm-agent/config.ini

#start and init mysql
service mysqld start
mysql -u root --password="$(grep password /var/log/mysqld.log | awk '{print $NF}')" --connect-expired-password < /root/init.sql

#init CM DB
/opt/cloudera/cm/schema/scm_prepare_database.sh -h "$MASTER_SERVER" mysql scm scm hadoop123

service cloudera-scm-server start

while [ `curl -o /dev/null --silent --head --write-out '%{http_code}\n' http://localhost:7180/cmf` != 200 ]; do
  sleep 2
done

service cloudera-scm-agent start

