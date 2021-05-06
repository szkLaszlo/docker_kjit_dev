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

export DISPLAY=`echo $DISPLAY | sed 's/^[^:]*\(.*\)/172.17.0.1\1/'`
export PYTHONPATH=$PYTHONPATH:/home/$HOST_USER/workspace:/home/$HOST_USER/remote_deployment

if [ "$START_SSH" = true ]; then
    service ssh start
fi
su $HOST_USER "$@"
