#!/bin/bash

set -ex

. /opt/kolla/kolla-common.sh

# create a dummy image which will be used in the tests
echo foo > /tmp/myimage.iso

set
python testglance.py

exit 0
			
