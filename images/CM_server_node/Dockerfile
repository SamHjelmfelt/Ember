ARG managerVersion
FROM samhjelmfelt/ember_cm_agent_node:$managerVersion

MAINTAINER Sam Hjelmfelt, samhjelmfelt@yahoo.com

# Install and configure CM server
RUN yum -y install cloudera-manager-server

# Install and init mysql
RUN wget http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm
RUN yum -y install ./mysql57-community-release-el7-7.noarch.rpm
RUN yum -y install mysql-community-server

# Install mysql connector
RUN wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz
RUN tar zxvf mysql-connector-java-5.1.46.tar.gz
RUN mkdir -p /usr/share/java/
RUN cp mysql-connector-java-5.1.46/mysql-connector-java-5.1.46-bin.jar /usr/share/java/mysql-connector-java.jar

ADD init.sql /root/

# Copy startup script
ADD startup.sh /root/
