FROM kollaglue/fedora-rdo-base

MAINTAINER Kolla Project (https://launchpad.net/kolla)

# Install required packages
RUN yum -y install \
  jq \
  python-glanceclient \
  python-devel pip gcc \ 
  && yum clean all

# need 1.0.13
RUN pip install python-ceilometerclient

# Copy start-up script
ADD start.sh /start.sh

RUN mkdir /tests
ADD test_*.sh /tests/
ADD test*.py /tests/
#ADD testkeystone.py /tests/

# Start test runner
CMD ["/start.sh"]
