FROM centos/systemd
ARG ambariVersion

MAINTAINER Sam Hjelmfelt, samhjelmfelt@yahoo.com

#systemd
STOPSIGNAL RTMIN+3

RUN yum install epel-release -y

# Open JDK 8
RUN yum install java-1.8.0-openjdk-devel -y
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk
ENV PATH $PATH:$JAVA_HOME/bin

# HDP Software Requirements that are not a part of centos base
RUN yum -y install sudo openssh-server openssh-clients unzip ntp wget yum-priorities tar initscripts systemd* less bind-utils ntpd

#Docker
RUN yum install -y yum-utils device-mapper-persistent-data lvm2
RUN yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
RUN yum install -y docker-ce

# default password
RUN echo "root:hadoop" | chpasswd

# Increase the yum timeout for slow installs
RUN sed -i "/\[main\]/a timeout=1800" /etc/yum.conf
RUN sed -i "/\[main\]/a retries=10" /etc/yum.conf

# Configure the Ambari Repository
RUN wget 'http://public-repo-1.hortonworks.com/ambari/centos7/'${ambariVersion:0:1}'.x/updates/'$ambariVersion'/ambari.repo' -O '/etc/yum.repos.d/ambari.repo'

RUN yum install ambari-agent -y

# Python SSL issues...https://community.hortonworks.com/questions/121978/openssl-compatibility.html?childToView=138080#answer-138080
RUN sed -i -e $'s/\[security\]/\[security\]\\nforce_https_protocol=PROTOCOL_TLSv1_2/g' /etc/ambari-agent/conf/ambari-agent.ini

# Copy startup script
ADD startup.sh /root/

# Copy docker wrapper and companion
ADD dockerwrapper.sh /opt/
ADD containerwatcher.sh /opt/
RUN chmod +x /opt/dockerwrapper.sh
RUN chmod +x /opt/containerwatcher.sh
