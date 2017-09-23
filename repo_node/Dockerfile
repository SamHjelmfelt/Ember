FROM centos/systemd

MAINTAINER Sam Hjelmfelt, shjelmfelt@hortonworks.com

# Shutdown systemd on 'docker stop'
# https://github.com/systemd/systemd/blob/master/src/core/manager.c#L447
STOPSIGNAL RTMIN+3

# Install and configure Ambari server and agent
RUN yum -y install httpd yum-utils createrepo wget
RUN chkconfig httpd on
RUN wget http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.4.0.1/ambari.repo -O /etc/yum.repos.d/ambari.repo
RUN wget -nv http://public-repo-1.hortonworks.com/HDP/centos7/2.x/updates/2.5.0.0/hdp.repo -O /etc/yum.repos.d/HDP.repo

RUN mkdir -p /var/www/html/hdp
RUN cd /var/www/html/hdp; reposync -r HDP-2.5.0.0
RUN cd /var/www/html/hdp; reposync -r HDP-UTILS-1.1.0.21
RUN cd /var/www/html/hdp; reposync -r Updates-ambari-2.4.0.1
RUN mkdir /etc/yum.repos.d/save
RUN mv /etc/yum.repos.d/HDP.repo /etc/yum.repos.d/save
RUN mv /etc/yum.repos.d/ambari.repo /etc/yum.repos.d/save
RUN createrepo /var/www/html/hdp/HDP-2.5.0.0/
RUN createrepo /var/www/html/hdp/HDP-UTILS-1.1.0.21/
RUN createrepo /var/www/html/hdp/Updates-ambari-2.4.0.1/
