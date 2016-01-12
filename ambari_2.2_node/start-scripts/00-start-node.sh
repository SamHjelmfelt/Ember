#!/bin/bash

chkconfig sshd on 
chkconfig ntpd on

/etc/init.d/sshd start
/etc/init.d/ntpd start

echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag
echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled

# Replace /etc/hosts file
umount /etc/hosts
echo "" >> /root/conf/hosts
echo "127.0.0.1   localhost" >> /root/conf/hosts
cp /root/conf/hosts /etc/

# The following link is used by all the Hadoop scripts
rm -rf /usr/java/default
mkdir -p /usr/java/default/bin/
ln -s /usr/bin/java /usr/java/default/bin/java

#Modify ambari-agent configuration to point to ambari server
sed -i "s/hostname=localhost/hostname=$AMBARI_SERVER/g" /etc/ambari-agent/conf/ambari-agent.ini 
