#!/bin/sh

set -e
. /opt/kolla/kolla-common.sh

: ${CEILOMETER_DB_USER:=ceilometer}
: ${CEILOMETER_DB_NAME:=ceilometer}
: ${KEYSTONE_AUTH_PROTOCOL:=http}
: ${CEILOMETER_KEYSTONE_USER:=admin}
: ${CEILOMETER_ADMIN_PASSWORD:=kolla}
: ${ADMIN_TENANT_NAME:=admin}
: ${METERING_SECRET:=ceilometer}

check_required_vars CEILOMETER_DB_PASSWORD KEYSTONE_ADMIN_TOKEN DB_ROOT_PASSWORD
dump_vars

cat > /openrc <<EOF
export SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
export SERVICE_ENDPOINT="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v2.0"
EOF


cfg=/etc/ceilometer/ceilometer.conf

crudini --set $cfg \
    DEFAULT rpc_backend rabbit
crudini --set $cfg \
    DEFAULT rabbit_host ${RABBITMQ_SERVICE_HOST}
crudini --set $cfg \
    DEFAULT rabbit_password ${RABBITMQ_PASS}

crudini --set $cfg \
    publisher \
    metering_secret \
    ${METERING_SECRET}
