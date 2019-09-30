#!/usr/bin/env bash
#
# Install.sh is the main entry point for installing any of the EAP demo applications.
#
# Usage: ./install.sh  [-h] <path-to-config.yml>
#

# Import our helper functions
. scripts/utils.sh

# Check all our pre reqs are installed
checkForRequirements

prettyHeader "ioFog Demo Application Installation"

# Is the user looking for help?
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echoInfo "Usage: `basename $0` [-h, --help] <path-to-demo-config.yml>"
  exit 0
fi

DEMO=${1%/*}
CONFIG="$1"

# What is the name of the demo we're installing?
echoInfo "Installing ${C_DEEPSKYBLUE4}${DEMO}${NO_FORMAT}${C_SKYBLUE1} Demo from ${1}"
echoInfo "Beginning installation process.."

# Call our python setup script
python3 ./setup.py --config ${CONFIG}
