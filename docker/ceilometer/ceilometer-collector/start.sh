#!/bin/sh

set -e

. /opt/kolla/kolla-common.sh
. /opt/kolla/config-ceilometer.sh

cfg=/etc/ceilometer/ceilometer.conf
crudini --set $cfg \
    database connection \
    "mysql://${CEILOMETER_DB_USER}:${CEILOMETER_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${CEILOMETER_DB_NAME}"



exec /usr/bin/ceilometer-collector
