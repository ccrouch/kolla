#!/bin/sh

. /opt/kolla/kolla-common.sh
. /opt/kolla/config-ceilometer.sh

check_required_vars KEYSTONE_AUTH_PROTOCOL CEILOMETER_KEYSTONE_USER CEILOMETER_ADMIN_PASSWORD ADMIN_TENANT_NAME

# this should return successfully only after the ceilometer keystone user
# has been properly setup
/opt/kolla/wait_for 30 1 keystone \
                    --os-auth-url=http://${KEYSTONE_PUBLIC_SERVICE_HOST}:${KEYSTONE_PUBLIC_SERVICE_PORT}/v2.0 \
                    --os-username=${CEILOMETER_KEYSTONE_USER} \
                    --os-tenant-name=${ADMIN_TENANT_NAME} \
                    --os-password=${CEILOMETER_ADMIN_PASSWORD} token-get
check_for_keystone

export SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
export SERVICE_ENDPOINT="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v2.0"

cfg=/etc/ceilometer/ceilometer.conf
# turn on debugging
crudini --set $cfg \
    DEFAULT debug \
    "True"
crudini --set $cfg \
    DEFAULT use_stderr \
    "True"

# setup creds for pulling metrics from other services
crudini --set $cfg \
    service_credentials \
    os_auth_url \
    http://api.dev5.mc.metacloud.in:35357/v2.0
#    ${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}:${KEYSTONE_PUBLIC_SERVICE_PORT}/v2.0
crudini --set $cfg \
    service_credentials \
    os_username \
    "glance"
#    "${CEILOMETER_KEYSTONE_USER}"
crudini --set $cfg \
    service_credentials \
    os_tenant_name \
    "service"    
#    "${ADMIN_TENANT_NAME}"
crudini --set $cfg \
    service_credentials \
    os_password \
    ahphaegheipuedaphohf
#    ${CEILOMETER_ADMIN_PASSWORD}



exec /usr/bin/ceilometer-agent-central
