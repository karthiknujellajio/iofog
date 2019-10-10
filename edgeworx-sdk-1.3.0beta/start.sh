#!/usr/bin/env bash
#
# start.sh - is a helper script to start a local ioFog ECN. You must have previously run './bootstrap.sh'.
#
# Usage : ./start.sh -h
#

set -e
cd "$(dirname "$0")"

# Import our helper functions
. ./scripts/utils.sh

prettyHeader "Starting Local ioFog ECN"

#
# Print out our usage
#
printHelp() {
	echoInfo "Usage: `basename $0` [-h, --help]"
    echo
    echoInfo "$0 will start your local ioFog ECN."
    exit 0
}

startIofog() {

    echoInfo "Spinning up containers for ioFog Local ECN ..."

    # Retrieve the container names for all our containers
    # These could have different endings based on what the user put into their local-stack.yml file
    AGENT_CONTAINER=$(docker ps -aq --filter="name=iofog-agent")
    CONTROLLER_CONTAINER=$(docker ps -aq --filter="name=iofog-controller")
    CONNECTOR_CONTAINER=$(docker ps -aq --filter="name=iofog-connector")

    echoInfo "  iofog-controller"
    docker start ${CONTROLLER_CONTAINER} > /dev/null 2>&1

    echoInfo "  iofog-connector"
    docker start ${CONNECTOR_CONTAINER} > /dev/null 2>&1

    echoInfo "  iofog-agent"
    docker start ${AGENT_CONTAINER} > /dev/null 2>&1

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

# Start ioFog stack
# TODO check if this is up already or not
startIofog

# Display the running environment
# Sleep to give the containers time to start
echo
sleep 2
./status.sh

