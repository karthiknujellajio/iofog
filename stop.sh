#!/usr/bin/env bash
#
# stop.sh - will shut down all of the local iofog containers.
#
# Usage : ./stop.sh -h
#

set -o errexit -o pipefail -o noclobber -o nounset

cd "$(dirname "$0")"

# Import our helper functions
. ./scripts/utils.sh

printHelp() {
	echo "Usage:   ./stop.sh"
	echo "Stops local ioFog stack containers"
	echo ""
	echo "Arguments:"
	echo "    -h, --help        print this help / usage"
}

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

prettyHeader "Stop ioFog Local ECN"

# Stop ioFog stack
echoInfo "Stopping all containers..."
AGENT_CONTAINER=$(docker ps -q --filter="name=iofog-agent-")
CONTROLLER_CONTAINER=$(docker ps -q --filter="name=iofog-controller-")
CONNECTOR_CONTAINER=$(docker ps -q --filter="name=iofog-connector-")
SERVICE_LIST="$CONTROLLER_CONTAINER $CONNECTOR_CONTAINER $AGENT_CONTAINER"
docker stop ${SERVICE_LIST}

# TODO stopping the ioFog stack leaves its microservices running - fix this properly
#REMAINING_MSVC=`docker ps -q --filter 'name=iofog*'`
#
#if [ ! -z "${REMAINING_MSVC}" ]; then
#    docker rm -f ${REMAINING_MSVC}
#fi

echo
echoSuccess "ioFog Local ECN is now stopped."
