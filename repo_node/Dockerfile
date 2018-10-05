FROM centos/systemd
ARG hdpVersion="2.6.5.0-292"

MAINTAINER Sam Hjelmfelt, shjelmfelt@hortonworks.com

# systemd
STOPSIGNAL RTMIN+3

RUN yum -y install httpd yum-utils createrepo wget
RUN chkconfig httpd on
RUN wget 'http://public-repo-1.hortonworks.com/HDP/centos7/2.x/updates/'${hdpVersion:0:7}'/hdp.repo' -O '/etc/yum.repos.d/HDP_'$hdpVersion'.repo'
RUN wget 'http://public-repo-1.hortonworks.com/HDP-GPL/centos7/2.x/updates/'${hdpVersion:0:7}'/hdp.gpl.repo' -O '/etc/yum.repos.d/HDP_'$hdpVersion'_GPL.repo'

RUN mkdir -p /var/www/html/hdp

RUN cd /var/www/html/hdp; reposync -r 'HDP-UTILS-'$(grep "\\[HDP-UTILS" '/etc/yum.repos.d/HDP_'$hdpVersion'.repo' | awk -F'[]-]' '{print $3}')
RUN cd /var/www/html/hdp; reposync -r 'HDP-'${hdpVersion:0:7}
RUN cd /var/www/html/hdp; reposync -r 'HDP-GPL-'${hdpVersion:0:7}

RUN createrepo '/var/www/html/hdp/HDP-UTILS-'$(grep "\\[HDP-UTILS" '/etc/yum.repos.d/HDP_'$hdpVersion'.repo' | awk -F'[]-]' '{print $3}')
RUN createrepo '/var/www/html/hdp/HDP-'${hdpVersion:0:7}
RUN createrepo '/var/www/html/hdp/HDP-GPL-'${hdpVersion:0:7}