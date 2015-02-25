FROM kollaglue/fedora-rdo-base
MAINTAINER Kolla Project (https://launchpad.net/kolla)

RUN yum -y install mariadb-galera-server; yum clean all
ADD /entrypoint.sh /entrypoint.sh

VOLUME /var/lib/mysql
VOLUME /var/log/mariadb

EXPOSE 3306

ENTRYPOINT ["/entrypoint.sh"]
# BUG msqld_safe eats signals so this will not shutdown cleanly
# but can't just blindly use mysqld since it wont start up when being
# run as root. Should look at how official mysql docker image does it
CMD ["mysqld_safe"]
