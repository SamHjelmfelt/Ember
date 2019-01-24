ARG managerVersion
FROM samhjelmfelt/ember_ambari_agent_node:$managerVersion

ARG mPacks=""

MAINTAINER Sam Hjelmfelt, samhjelmfelt@yahoo.com

# Install and configure Ambari server and agent
RUN yum -y install ambari-server

# Download the MySql client connector JAR and link it to the resources folder
RUN wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.12-1.el7.noarch.rpm
RUN yum -y install mysql-connector-java-8.0.12-1.el7.noarch.rpm
RUN ln -s /usr/share/java/mysql-connector-java-8.0.12.jar /var/lib/ambari-server/resources/mysql-connector-java.jar

# Install mPacks
RUN for i in ${mPacks//,/ }; do if [ -n "$i" ]; then ambari-server install-mpack --mpack=$i; fi;  done

# Copy startup script
ADD startup.sh /root/
