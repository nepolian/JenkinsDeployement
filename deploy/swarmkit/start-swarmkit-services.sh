#!/bin/bash

# if [ -z ${SWARM_SOCKET} ]; then
#     echo "SWARM_SOCKET environment variable is unset."
#     exit 1
# fi

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

exit_on_failure() {
    if [ $? -ne 0 ]; then
        echo "Command failed"
        exit 1;
    fi
}

cleanup_services() {
    docker service rm front-end
    docker service rm edge-router
    docker service rm catalogue
    docker service rm weave-scope
}

if ! command_exists "docker" ; then
    echo "Please ensure that docker cermand is on the \$PATH"
    exit 1
fi

if [ "$1" == "cleanup" ]; then
    echo "Cleaning up services"
    cleanup_services
    exit 0;
fi

echo "Creating front-end service"
docker service create \
       --network ingress \
       #       --publish 8079 \
       --name front-end --env "reschedule=on-node-failure" weaveworksdemos/front-end:latest

exit_on_failure

echo "Creating edge-router service"
docker service create \
       --name edge-router \
       #       --publish 80 \
       --network ingress \
       --env "reschedule=on-node-failure" weaveworksdemos/edge-router:latest

exit_on_failure

echo "Creating catalogue service"
docker service create \
       --name catalogue \
       --network ingress \
       --env "reschedule=on-node-failure" weaveworksdemos/catalogue:latest
exit_on_failure

echo "Creating weave scope service"
docker service create \
       --name weave-scope \
       #       --publish 4040 \
       --network ingress weaveworks/scope:0.15 "--probe.docker" "true"
exit_on_failure

echo "Done"
