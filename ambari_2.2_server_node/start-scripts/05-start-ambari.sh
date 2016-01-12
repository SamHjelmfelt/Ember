#!/bin/bash

sed -i "/^      os.killpg(os.getpgid(pid), signal.SIGKILL)/c\      os.kill(pid, signal.SIGKILL)" /usr/sbin/ambari-server.py
sed -i "/agent.task.timeout=600/c\agent.task.timeout=3000" /etc/ambari-server/conf/ambari.properties
find /var/lib/ambari-server/resources/stacks/ -name metainfo.xml | while read file; do 
  sed -i "/<timeout>.*<\/timeout>/c\<timeout>3000<\/timeout>" $file 
done

service httpd start

ambari-server start

while [ `curl -o /dev/null --silent --head --write-out '%{http_code}\n' http://${AMBARI_SERVER}:8080` != 200 ]; do
  sleep 2
done

ambari-agent start

