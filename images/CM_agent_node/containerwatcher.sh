#!/bin/bash
#This script and its companion "/opt/dockerwrapper.sh" are necessary to enable Docker on YARN from inside Docker container)
# 1. The docker socket can not be mounted into a container under /var/run, so the -H flag (or DOCKER_HOST env) is necessary for all docker commands
# 2. YARN watches the PID of all spawned containers to see if they are still alive.
#       Since the container is launched on the host rather than in the container that YARN runs in,
#       the PID in the hosts namespace and therefore not accessible to YARN.
#       This script creates a process that watches the container using docker commands.
#       The PID of this watcher process is then given to YARN to watch as a proxy for the container.
#YARN behaves as expected with these two changes.
sleep 10;
status=$(docker -H "unix:///host/var/run/docker.sock" inspect --format={{.State.Status}} "$1")
while [ "$status" == "running" ]; do
  sleep 1;
done;