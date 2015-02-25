FROM kollaglue/fedora-rdo-ceilometer-base
MAINTAINER Kolla Project (https://launchpad.net/kolla)

RUN yum install -y openstack-ceilometer-notification && yum clean all

# Fedora Juno openstack-ceilometer-notification doesn't install this by default
# TODO why is this needed though? I thought notification agent just spoke 
# "messaging"?
RUN yum install -y \
        python-oslo-db \
        ; yum clean all


ADD ./start.sh /start.sh
CMD ["/start.sh"]
