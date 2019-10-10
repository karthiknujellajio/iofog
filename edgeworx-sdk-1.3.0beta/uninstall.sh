#!/usr/bin/env sh
#
# Uninstall.sh will remove any of the EAP demo applications.
#
# Usage: ./uninstall.sh [-h] <path-to-config.yml>
#

# Import our helper functions
. scripts/utils.sh

prettyHeader "ioFog Demo Application Uninstall"

# Is the user looking for help?
if [ "$1" == "-h" ]; then
  echoInfo "Usage: `basename $0` [-h] <path-to-demo-config.yml>"
  exit 0
fi

# What is the name of the demo we're uninstalling?
DEMO=${1%/*}
CONFIG="$1"

echoInfo "Removing ${C_DEEPSKYBLUE4}${DEMO}${NO_FORMAT}${C_SKYBLUE1} Demo"
echoInfo "Beginning uninstall process.."

# Call iofogctl delete application
APP_NAME=$(cat "$CONFIG" | grep "name:" | awk 'NR == 1 {print $2}' | tr -d \")
iofogctl -v delete application $APP_NAME --http-verbose
