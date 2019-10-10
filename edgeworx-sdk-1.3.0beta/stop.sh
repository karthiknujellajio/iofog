#!/usr/bin/env bash
#
# stop.sh - will shut down all of the local iofog containers.
#
# Usage : ./stop.sh -h
#

set -e
cd "$(dirname "$0")"

# Import our helper functions
. ./scripts/utils.sh

prettyHeader "Stopping Local ioFog ECN"

#
# Print out our usage
#
printHelp() {
    echoInfo "Usage: `basename $0` [-h, --help]"
    echo
    echoInfo "$0 will shut down your running local ioFog ECN."
    exit 0
}

# Check for cmdline options
while [[ "$#" -ge 1 ]]; do
    case "$1" in
        -h|--help)
            printHelp
            exit 0
            ;;
        *)
            echoError "Unrecognized argument: \"$1\""
            printHelp
            exit 1
            ;;
    esac
done

# Stop ioFog stack
stopIofog() {
    echoInfo "Stopping all ioFog containers..."
    AGENT_CONTAINER=$(docker ps -q --filter="name=iofog-agent")
    CONTROLLER_CONTAINER=$(docker ps -q --filter="name=iofog-controller")
    CONNECTOR_CONTAINER=$(docker ps -q --filter="name=iofog-connector")

    echoInfo "  iofog-controller"
    docker stop ${CONTROLLER_CONTAINER} > /dev/null 2>&1

    echoInfo "  iofog-connector"
    docker stop ${CONNECTOR_CONTAINER} > /dev/null 2>&1

    echoInfo "  iofog-agent"
    docker stop ${AGENT_CONTAINER} > /dev/null 2>&1
}

# Stop the containers
stopIofog

# TODO stopping the ioFog stack leaves its microservices running - fix this properly
#REMAINING_MSVC=`docker ps -q --filter 'name=iofog*'`
#
#if [ ! -z "${REMAINING_MSVC}" ]; then
#    docker rm -f ${REMAINING_MSVC}
#fi

echo
echoSuccess "ioFog Local ECN is now stopped."
