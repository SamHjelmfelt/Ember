FROM centos:centos6

MAINTAINER Sam Hjelmfelt, shjelmfelt@hortonworks.com

# HDP Software Requirements that are not a part of centos base
RUN yum -y install openssh-server openssh-clients unzip ntp wget yum-priorities tar

# sudo is needed to run the Hadoop binaries
#RUN yum -y install sudo bind-utils zip

# Configure the Ambari Repository for 2.2.0.0
RUN wget http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.2.0.0/ambari.repo -O /etc/yum.repos.d/ambari.repo

# Copy scripts and config files onto new container
RUN mkdir /root/scripts && mkdir /root/conf && mkdir /root/start-scripts
ADD conf/ /root/conf/
ADD conf/config /etc/selinux/config
ADD scripts/ /root/scripts/
ADD start-scripts/ /root/start-scripts/

RUN echo "source /etc/bashrc" >> /root/.bash_profile

#RUN systemctl disable firewalld

RUN echo "root:hadoop" | chpasswd

# Add Java to the path
RUN echo "export JAVA_HOME=/usr/jdk64/jdk1.8.0_40/" >> /etc/bashrc
RUN echo "export PATH=/usr/jdk64/jdk1.8.0_40/bin:\$PATH" >> /etc/bashrc

# Increase the yum timeout for slow installs
RUN sed -i "/\[main\]/a timeout=1800" /etc/yum.conf
RUN sed -i "/\[main\]/a retries=10" /etc/yum.conf

EXPOSE 22 8010 8020 9000 50070 8088 8032 50060 9000 50075 50010 50020 50060 50090 10000 9999 9933 8081 8030 8050 8025 8141 19888 45454 10020 2181 50111 9083 11000 8080 3372 3373 6627 6700 6701 6702 6703 9080 9081 9082 9083 9084 9085 9086 9087

ENTRYPOINT ["/root/scripts/startup.sh"]

