#!/bin/sh

set -e

. /opt/kolla/kolla-common.sh
. /opt/kolla/config-glance.sh
: ${GLANCE_API_SERVICE_HOST:=$PUBLIC_IP}

set -x
check_required_vars KEYSTONE_ADMIN_TOKEN KEYSTONE_ADMIN_SERVICE_HOST \
                    GLANCE_KEYSTONE_USER GLANCE_KEYSTONE_PASSWORD \
                    ADMIN_TENANT_NAME GLANCE_API_SERVICE_HOST \
                    PUBLIC_IP

/opt/kolla/wait_for 30 1 keystone \
                    --os-auth-url=http://${KEYSTONE_PUBLIC_SERVICE_HOST}:35357/v2.0 \
                    --os-username=admin --os-tenant-name=${ADMIN_TENANT_NAME} \
                    --os-password=${KEYSTONE_ADMIN_PASSWORD} endpoint-list
check_for_keystone

export SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
export SERVICE_ENDPOINT="http://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/v2.0"
#BUG
# currently there is a race condition between this user-create command and the 
# corresponding one in keystone/start.sh. The race can be triggered because
# both calls reference the admin tenant and admin role, which crux will
# try to create if not present. The crux tool is not meant to be run
# concurrently so you can end up with two requests to create the
# admin tenant being fired off to keystone, one of which will fail and
# cause the corresponding start.sh to exit and terminate the container
# 
# The solution is to just to let the keystone script create the admin
# tenant and role. We should be able to do that by fixing the wait_for 
# command above so that it actually verifies those things have already
# been created
# i) authenticate as the admin user and admin tenant, this obviously ensures
# that the admin tenant already exists.
# ii) call an action which requires the user have the admin role, e.g. 
# endpoint-list, this obviously ensures the admin role already exists

crux user-create --update \
    -n "${GLANCE_KEYSTONE_USER}" \
    -p "${GLANCE_KEYSTONE_PASSWORD}" \
    -t "${ADMIN_TENANT_NAME}" \
    -r admin

crux endpoint-create --remove-all \
    -n glance -t image \
    -I "http://${GLANCE_API_SERVICE_HOST}:9292" \
    -P "http://${PUBLIC_IP}:9292" \
    -A "http://${GLANCE_API_SERVICE_HOST}:9292"

# turn on notification sending by glance
crudini --set /etc/glance/glance-api.conf \
    DEFAULT \
    notification_driver \
    "messaging"

crudini --set /etc/glance/glance-api.conf \
    DEFAULT \
    rabbit_host \
    "${RABBITMQ_SERVICE_HOST}"

crudini --set /etc/glance/glance-api.conf \
    DEFAULT \
    registry_host \
    "${GLANCE_REGISTRY_SERVICE_HOST}"

crudini --set /etc/glance/glance-api.conf \
    DEFAULT \
    debug \
    "True"

exec /usr/bin/glance-api
