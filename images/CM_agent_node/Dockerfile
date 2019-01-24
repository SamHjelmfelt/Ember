FROM centos/systemd
ARG managerVersion

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

# Configure the Cloudera Manager Repository
RUN wget "https://archive.cloudera.com/cm${managerVersion:0:1}/${managerVersion}/redhat7/yum/cloudera-manager.repo" -P /etc/yum.repos.d/
RUN rpm --import "https://archive.cloudera.com/cm${managerVersion:0:1}/${managerVersion}/redhat7/yum/RPM-GPG-KEY-cloudera"

RUN yum install cloudera-manager-agent cloudera-manager-daemons -y

# Copy startup script
ADD startup.sh /root/

# Copy docker wrapper and companion
ADD dockerwrapper.sh /opt/
ADD containerwatcher.sh /opt/
RUN chmod +x /opt/dockerwrapper.sh
RUN chmod +x /opt/containerwatcher.sh
