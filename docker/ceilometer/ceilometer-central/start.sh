#!/bin/sh

. /opt/kolla/kolla-common.sh
. /opt/kolla/config-ceilometer.sh

check_required_vars KEYSTONE_AUTH_PROTOCOL CEILOMETER_KEYSTONE_USER CEILOMETER_ADMIN_PASSWORD ADMIN_TENANT_NAME

check_for_keystone
check_for_db

export SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
export SERVICE_ENDPOINT="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v2.0"

# turn on debugging
cfg=/etc/ceilometer/ceilometer.conf
crudini --set $cfg \
    DEFAULT debug \
    "True"

crudini --set $cfg \
    DEFAULT use_stderr \
    "True"

exec /usr/bin/ceilometer-agent-central
