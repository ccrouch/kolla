FROM kollaglue/fedora-rdo-base
MAINTAINER Kolla Project (https://launchpad.net/kolla)

# Fedora Juno ceilometer-api package doesn't install these by default
# TODO IMHO these should be moved out of base into -api and just the
# required ones added individually to ceilometer-*/Dockerfile
RUN yum install -y \
        MySQL-python \
        python-ceilometerclient \
        python-tooz \
        ; yum clean all

RUN mkdir -p /opt/kolla
COPY config-ceilometer.sh /opt/kolla/config-ceilometer.sh
