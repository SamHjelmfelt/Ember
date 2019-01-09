#!/bin/bash
#This script and its companion "/opt/dockerwrapper.sh" are necessary to enable Docker on YARN from inside Docker container)
# 1. The docker socket can not be mounted into a container under /var/run, so the -H flag (or DOCKER_HOST env) is necessary for all docker commands
# 2. YARN watches the PID of all spawned containers to see if they are still alive.
#       Since the container is launched on the host rather than in the container that YARN runs in,
#       the PID in the hosts namespace and therefore not accessible to YARN.
#       This script creates a process that watches the container using docker commands.
#       The PID of this watcher process is then given to YARN to watch as a proxy for the container.
#YARN behaves as expected with these two changes.
#echo "$(date "+%Y-%m-%d %H:%M:%S") $@" >> /opt/docker.log

result=$(docker -H "unix:///host/var/run/docker.sock" "$@")

if [ "$3" == "{{.State.Pid}}" ]; then
    name="$4"
    pid=$(pgrep -f "/opt/containerwatcher.sh $name")
    if [ -z $pid ]; then
      exec /opt/containerwatcher.sh "$name" &
      pid=$!
      #echo "ran $name watcher (pid: $pid)" >> /opt/docker.log
    fi
    result=$pid
    #echo "replaced pid ($pid) for $name" >> /opt/docker.log
elif [ "$1" == "rm" ]; then
  name="$2"
  pid=$(pgrep -f "/opt/containerwatcher.sh $name")
  kill $pid
  #echo "killed $2 watcher (pid: $pid)" >> /opt/docker.log
fi

#echo "$result" >> /opt/docker.log
echo $result
