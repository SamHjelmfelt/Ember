FROM centos/systemd
ARG ambariVersion

MAINTAINER Sam Hjelmfelt, shjelmfelt@hortonworks.com

#systemd
STOPSIGNAL RTMIN+3

RUN yum install epel-release -y

# Open JDK 8
RUN yum install java-1.8.0-openjdk-devel -y
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk
ENV PATH $PATH:$JAVA_HOME/bin

# HDP Software Requirements that are not a part of centos base
RUN yum -y install sudo openssh-server openssh-clients unzip ntp wget yum-priorities tar initscripts systemd* less bind-utils ntpd

# default password
RUN echo "root:hadoop" | chpasswd

# Increase the yum timeout for slow installs
RUN sed -i "/\[main\]/a timeout=1800" /etc/yum.conf
RUN sed -i "/\[main\]/a retries=10" /etc/yum.conf


EXPOSE 22 8010 8020 9000 50070 8088 8032 50060 9000 50075 50010 50020 50060 50090 10000 9999 9933 8081 8030 8050 8025 8141 19888 45454 10020 2181 50111 9083 11000 8080 3372 3373 6627 6700 6701 6702 6703 9080 9081 9082 9083 9084 9085 9086 9087


# Configure the Ambari Repository
RUN wget 'http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/'$ambariVersion'/ambari.repo' -O '/etc/yum.repos.d/ambari.repo'

RUN yum install ambari-agent -y

# Python SSL issues...https://community.hortonworks.com/questions/121978/openssl-compatibility.html?childToView=138080#answer-138080
RUN sed -i -e $'s/\[security\]/\[security\]\\nforce_https_protocol=PROTOCOL_TLSv1_2/g' /etc/ambari-agent/conf/ambari-agent.ini

# Copy startup script
ADD startup.sh /root/


