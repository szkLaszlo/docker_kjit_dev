#!/usr/bin/env bash
if [ -z "$1" ]; then
    START_SSH=false
else
    START_SSH=$1
    shift
fi

echo "$HOST_USER:x:$HOST_UID:" >> /etc/group
echo "docker:x:999:$HOST_USER" >> /etc/group
useradd -u $HOST_UID -g $HOST_UID -d /home/$HOST_USER -s /bin/bash -M $HOST_USER
passwd $HOST_USER docker1234
if [ "$START_SSH" = true ]; then
    service ssh start
fi

exec su $HOST_USER "$@"
