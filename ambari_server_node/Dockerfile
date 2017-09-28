ARG ambariVersion
FROM 'dockerdoop/ambari_agent_node_'$ambariVersion

ARG mPacks=""

MAINTAINER Sam Hjelmfelt, shjelmfelt@hortonworks.com

# Install and configure Ambari server and agent
RUN yum -y install ambari-server

# Install mPacks
RUN for i in ${mPacks//,/ }; do if [ -n "$i" ]; then ambari-server install-mpack --mpack=$i; fi;  done

# Copy startup script
ADD startup.sh /root/
