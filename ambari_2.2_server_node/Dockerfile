FROM hwxu/ambari_2.2_node

MAINTAINER Sam Hjelmfelt, shjelmfelt@hortonworks.com

RUN yum -y install httpd yum-utils createrepo
RUN chkconfig httpd on
RUN wget -nv http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.3.4.0/hdp.repo -O /etc/yum.repos.d/HDP.repo

RUN mkdir -p /var/www/html/hdp
RUN cd /var/www/html/hdp; reposync -r HDP-2.3.4.0
RUN cd /var/www/html/hdp; reposync -r HDP-UTILS-1.1.0.20
RUN mkdir /etc/yum.repos.d/save
RUN mv /etc/yum.repos.d/HDP.repo /etc/yum.repos.d/save
RUN createrepo /var/www/html/hdp/HDP-2.3.4.0/
RUN createrepo /var/www/html/hdp/HDP-UTILS-1.1.0.20/

# Install and configure Ambari server and agent
RUN yum clean all
RUN yum -y install ambari-server ambari-agent
RUN ambari-server setup -s -v

ADD start-scripts/ /root/start-scripts
