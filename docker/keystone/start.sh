#!/bin/bash

set -e

: ${KEYSTONE_ADMIN_PASSWORD:=kolla}
: ${ADMIN_TENANT_NAME:=admin}

. /opt/kolla/kolla-common.sh
: ${KEYSTONE_ADMIN_SERVICE_HOST:=$PUBLIC_IP}
: ${KEYSTONE_PUBLIC_SERVICE_HOST:=$PUBLIC_IP}

# lets wait for the DB to be available
./opt/kolla/wait_for 25 1 mysql -h ${MARIADB_SERVICE_HOST} -u root -p"${DB_ROOT_PASSWORD}" -e 'status;'
check_for_db
check_required_vars KEYSTONE_ADMIN_TOKEN KEYSTONE_DB_PASSWORD \
                    KEYSTONE_ADMIN_PASSWORD ADMIN_TENANT_NAME \
                    KEYSTONE_PUBLIC_SERVICE_HOST KEYSTONE_ADMIN_SERVICE_HOST
dump_vars

mysql -h ${MARIADB_SERVICE_HOST} -u root -p"${DB_ROOT_PASSWORD}" mysql <<EOF
CREATE DATABASE IF NOT EXISTS keystone;
GRANT ALL PRIVILEGES ON keystone.* TO
    'keystone'@'%' IDENTIFIED BY '${KEYSTONE_DB_PASSWORD}'
EOF

crudini --set /etc/keystone/keystone.conf \
    database \
    connection \
    "mysql://keystone:${KEYSTONE_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/keystone"
crudini --set /etc/keystone/keystone.conf \
    DEFAULT \
    admin_token \
    "${KEYSTONE_ADMIN_TOKEN}"
crudini --set /etc/keystone/keystone.conf \
    DEFAULT \
    log_file \
    ""
crudini --set /etc/keystone/keystone.conf \
    DEFAULT \
    debug \
    "True"
crudini --del /etc/keystone/keystone.conf \
    DEFAULT \
    log_dir
crudini --set /etc/keystone/keystone.conf DEFAULT use_stderr True

cat > /openrc <<EOF
export OS_AUTH_URL="http://${KEYSTONE_PUBLIC_SERVICE_HOST}:5000/v2.0"
export OS_USERNAME=admin
export OS_PASSWORD="${KEYSTONE_ADMIN_PASSWORD}"
export OS_TENANT_NAME=${ADMIN_TENANT_NAME}
EOF

/usr/bin/keystone-manage db_sync
/usr/bin/keystone-manage pki_setup --keystone-user keystone --keystone-group keystone

trap 'kill -TERM $PID; wait $PID' TERM
echo "Running keystone service."
/usr/bin/keystone-all &
PID=$!

export SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
export SERVICE_ENDPOINT="http://${MY_IP}:35357/v2.0"

while ! curl -o /dev/null -s --fail ${SERVICE_ENDPOINT}; do
    echo "waiting for keystone @ ${SERVICE_ENDPOINT}"
    sleep 1;
done
echo "keystone is active @ ${SERVICE_ENDPOINT}"

crux user-create --update \
    -n admin -p "${KEYSTONE_ADMIN_PASSWORD}" \
    -t admin -r admin
crux endpoint-create --remove-all \
    -n keystone -t identity \
    -I "http://${KEYSTONE_PUBLIC_SERVICE_HOST}:5000/v2.0" \
    -A "http://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/v2.0" \
    -P "http://${PUBLIC_IP}:5000/v2.0"

# BUG
# I can find no reason why the keystone-all prcoess was being killed here, other
# than the desire to make it PID1. 
# Here is the original commit:
# https://github.com/stackforge/kolla/commit/2a27886421570fd78fcc3f847cb640464b8377ef
# Killing the keystone-all process here introduces a bug whereby a service that 
# depends on keystone e.g. glance-api, can wait for keystone to be ready, which it will
# be as soon as the endpoint is created, but then try to call the service and find 
# that its down and in the middle of this kill/start process.
# So instead of doing kill/start we just setup the trap above and the wait below
# so that signals sent to this script will be passed to the original 
# keystone-all process appropriately
wait $PID
