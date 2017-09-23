#!/bin/bash


yum -y install httpd yum-utils createrepo
chkconfig httpd on
wget -nv http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.4.2.0/hdp.repo -O /etc/yum.repos.d/HDP.repo

mkdir -p /var/www/html/hdp
cd /var/www/html/hdp; reposync -r HDP-2.4.2.0
cd /var/www/html/hdp; reposync -r HDP-UTILS-1.1.0.20
mkdir /etc/yum.repos.d/save
mv /etc/yum.repos.d/HDP.repo /etc/yum.repos.d/save
createrepo /var/www/html/hdp/HDP-2.4.2.0/
createrepo /var/www/html/hdp/HDP-UTILS-1.1.0.20/