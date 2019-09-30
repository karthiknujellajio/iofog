#!/usr/bin/env bash
#
# start.sh - is a helper script to start a local ioFog ECN. You must have previously run './bootstrap.sh'.
#
# Usage : ./start.sh -h
#

set -o errexit -o pipefail -o noclobber -o nounset

cd "$(dirname "$0")"

# Import our helper functions
. ./scripts/utils.sh

printHelp() {
	echo "Usage:   ./start.sh"
	echo "Starts ioFog Local ECN containers"
	echo ""
	echo "Arguments:"
	echo "    -h, --help        print this help / usage"
}

startIofog() {

    echoInfo "Spinning up containers for ioFog Local ECN ..."

    # Retrieve the container names for all our containers
    # These could have different endings based on what the user put into their local-stack.yml file
    AGENT_CONTAINER=$(docker ps -aq --filter="name=iofog-agent-")
    CONTROLLER_CONTAINER=$(docker ps -aq --filter="name=iofog-controller-")
    CONNECTOR_CONTAINER=$(docker ps -aq --filter="name=iofog-connector-")

    SERVICE_LIST="$CONTROLLER_CONTAINER $CONNECTOR_CONTAINER $AGENT_CONTAINER"

    # Start 'em up!
    docker start ${SERVICE_LIST}

    echoSuccess "Successfully started ioFog Local ECN stack"
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

prettyHeader "Starting ioFog Local ECN"

# Start ioFog stack
# TODO check if this is up already or not
startIofog

# Display the running environment
./status.sh

