#!/usr/bin/env sh
#
# Uninstall.sh will remove any of the EAP demo applications.
#
# Usage: ./uninstall.sh [-h] <path-to-config.yml>
#

# Import our helper functions
. scripts/utils.sh

checkForRequirements

prettyHeader "ioFog Demo Application Uninstall"

# Is the user looking for help?
if [ "$1" == "-h" ]; then
  echoInfo "Usage: `basename $0` [-h] <path-to-demo-config.yml>"
  exit 0
fi

# What is the name of the demo we're uninstalling?
DEMO=${1%/*}
echoInfo "Removing ${C_DEEPSKYBLUE4}${DEMO}${NO_FORMAT}${C_SKYBLUE1} Demo"
echoInfo "Beginning uninstall process.."

# Call our python setup script
python3 ./setup.py --config ${1} --clean
