#!/usr/bin/env bash
#
# status.sh - Print the status of the local ECN and its components
#
# Usage: ./status.sh
#

set -e
cd "$(dirname "$0")"

# Import our helper functions
. ./scripts/utils.sh

# Display the running environment
prettyTitle "ioFog Local ECN Status"

# Are any of our containers running?
ECN_CONTAINERS=$(docker ps --filter 'name=iofog' | wc -l)

if [[ ${ECN_CONTAINERS} -gt 1 ]]; then

    echoInfo " $(docker ps --filter 'name=iofog')"
    echo

    # Figure out if there is an iofog-controller running
    CONTROLLER_CONTAINER=$(docker ps -q --filter="name=iofog-controller-")

    if [[ ! -z ${CONTROLLER_CONTAINER} ]]; then

        # Can we extract the port?
        CONTROLLER_PORT="$(docker port ${CONTROLLER_CONTAINER}  | awk '{print $1}' | cut -b 1-5)"

        if [[ ! -z ${CONTROLLER_PORT} ]]; then
            echoSuccess "iofog-controller is running at http://localhost:${CONTROLLER_PORT}"
        else
            echoError "iofog-controller container is running on http://localhost but unable to find CONTROLLER_PORT."
        fi
    else
        echoInfo "No iofog-controller container was found."
    fi

else
    echo
    echoInfo "ioFog Local ECN is not running. You can start it by running './start.sh'."
fi
