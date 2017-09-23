#!/bin/bash

systemctl enable sshd.service
systemctl enable ntpd.service

systemctl start sshd.service
systemctl start ntpd.service

#echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag
#echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled

# The following link is used by all the Hadoop scripts
rm -rf /usr/java/default
mkdir -p /usr/java/default/bin/
ln -s /usr/bin/java /usr/java/default/bin/java

#Modify ambari-agent configuration to point to ambari server
sed -i "s/hostname=localhost/hostname=$AMBARI_SERVER/g" /etc/ambari-agent/conf/ambari-agent.ini 
