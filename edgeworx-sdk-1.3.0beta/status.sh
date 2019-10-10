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

#
# Print out our usage
#
printHelp() {
    echoInfo "Usage: `basename $0` [-h, --help] [--containers]"
    echo
    echoInfo "$0 display the status of your local ioFog stack."
    echoInfo "--containers will display additional docker information."
    exit 0
}

# Is the user looking for help?
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    printHelp
fi

# Are any of our containers running?
ECN_CONTAINERS=$(docker ps --filter 'name=iofog' | wc -l)

if [[ ${ECN_CONTAINERS} -gt 1 ]]; then

    if [[ "$1" == "--containers" ]]; then
        echoInfo " $(docker ps --filter 'name=iofog')"
        echo
    fi

    # Figure out if there is an iofog-controller running
    CONTROLLER_CONTAINER=$(docker ps -q --filter="name=iofog-controller")

    if [[ ! -z ${CONTROLLER_CONTAINER} ]]; then
        iofogctl get all
        echoSuccess "iofog-controller is running at http://localhost:51121"
        echoSuccess "ECN Viewer is running at http://localhost:8008"
        EMAIL=$(grep email local-stack.yml | tr -d ' ')
        PASSWD=$(grep password local-stack.yml | tr -d ' ')
        echoSuccess "Connect to your ECN Viewer using ${EMAIL} and ${PASSWD}."
    else
        echoInfo "No iofog-controller container was found."
    fi

else
    echo
    echoInfo "ioFog Local ECN is not running. You can start it by running './start.sh'."
fi
