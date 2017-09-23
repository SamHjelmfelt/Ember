FROM hwxu/ambari_2.4_node

MAINTAINER Sam Hjelmfelt, shjelmfelt@hortonworks.com


# Install and configure Ambari server and agent
RUN yum clean all
RUN yum -y install ambari-server ambari-agent

ADD start-scripts/ /root/start-scripts
