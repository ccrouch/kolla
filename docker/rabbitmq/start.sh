#!/bin/sh

set -e

: ${RABBITMQ_USER:=guest}
: ${RABBITMQ_PASS:=guest}
: ${RABBITMQ_NODE_PORT:=5672}
: ${RABBITMQ_LOG_BASE:=/var/log/rabbitmq}

sed -i '
	s|@RABBITMQ_USER@|'"$RABBITMQ_USER"'|g
	s|@RABBITMQ_PASS@|'"$RABBITMQ_PASS"'|g
' /etc/rabbitmq/rabbitmq.config

sed -i '
	s|@RABBITMQ_PORT@|'"$RABBITMQ_NODE_PORT"'|g
	s|@RABBITMQ_LOG_BASE@|'"$RABBITMQ_LOG_BASE"'|g
' /etc/rabbitmq/rabbitmq-env.conf

# BUG
# There doesn't seem to be an optimal way to actually start the rabbit 
# server process :-(
# The current way of doing it
#    exec /usr/lib/rabbitmq/bin/rabbitmq-server
# means that the process is started as root, so the .erlang.cookie which is
# created will be in $HOME=/root. This is fine until you attach to the container
# and try to use the builtin tools such as rabbitmqctl. The problem with this
# is that the rabbitmqctl script in the path is /usr/sbin/rabbitmqctl which calls
# su rabbitmq before calling /usr/lib/rabbitmq/bin/rabbitmqctl, which means
# that rabbitmqctl will use the .erlang.cookie in $HOME=/var/lib/rabbitmq/
# which won't match the one that was used when the rabbitmq server was started :-(
# To work around this you have to copy the cookie from /root to 
# /var/lib/rabbitmq and set the ownership to rabbitmq, or you can just not use
# the rabbitmqctl in $PATH and use the fully qualifed version:
# /usr/lib/rabbitmq/bin/rabbitmqctl
#
# Alternatives such as the one used in the default rabbitmq docker image is
# to just to call 
#   exec rabbitmq-server
# which calls /usr/sbin/rabbitmq-server and everything works as expected, but you 
# are left with this script as PID1 in the container. I think this is because
# of the user switching which /usr/sbin/rabbitmq-server does: this script runs
# as root as PID1 and eventually /usr/lib/rabbitmq/bin/rabbitmq-server is also 
# running but as the rabbitmq user.
# Even if you do something like 
#   exec su rabbitmq -c "rabbitmq-server" 
# you still don't have the main rabbitmq-server process running as PID1

exec /usr/lib/rabbitmq/bin/rabbitmq-server
