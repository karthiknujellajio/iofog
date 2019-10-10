#!/usr/bin/env bash
#
# bootstrap.sh will configure an ioFog Demo repo to use the local EAP packages.
#
# Usage: ./bootstrap.sh [-h, --help]
#

set -e

# Import our helper functions
. ./scripts/utils.sh

DOCKER_INSTALL_URL="https://docs.docker.com/"
DOCKER_DARWIN_URL="https://docs.docker.com/docker-for-mac/install/"

prettyHeader "ioFog SDK Bootstrap"

#
# Print out our usage
#
printHelp() {
    echoInfo "Usage: `basename $0` [-h, --help] [--destroy]"
    echo
    echoInfo "$0 will deploy a local ioFog stack using docker containers."
    echoInfo "--destroy will remove any existing local ioFog stack."
    exit 0
}


#
# Check between apt or yum
#
install_iofogctl_linux() {
    if ! [[ -x "$(command -v curl)" ]]; then
        echoError " 'curl' not found, Please install and re-run bootstrap.sh."
        exit 1
    fi
    if [[ -x "$(command -v apt-get)" ]]; then
        curl -s https://packagecloud.io/install/repositories/iofog/iofogctl/script.deb.sh | sudo bash
        sudo apt-get install iofogctl -y
    elif [[ -x "$(command -v apt)" ]]; then
        curl -s https://packagecloud.io/install/repositories/iofog/iofogctl/script.deb.sh | sudo bash
        sudo apt install iofogctl -y
    elif [[ -x "$(command -v yum)" ]]; then
        curl -s https://packagecloud.io/install/repositories/iofog/iofogctl/script.rpm.sh | sudo bash
        sudo yum install iofogctl -y
    else
        iofogctl_install_exit
    fi
}

install_iofogctl_win() {
    echoInfo "We do not currently support Windows."
    exit 1
}

install_iofogctl_darwin() {
    if [[ -x "$(command -v brew)" ]]; then
        brew tap eclipse-iofog/iofogctl
        brew install eclipse-iofog/iofogctl/iofogctl@1.3
    else
        echoInfo "'brew' not found, please install and re-run bootstrap.sh."
        iofogctl_install_exit
    fi
}

iofogctl_install_exit() {
    echoInfo "Could not detect package installation system."
    echoInfo "Please follow Github instructions to install iofogctl: https://github.com/eclipse-iofog/iofogctl"
    exit 1
}

#
# Install iofogctl
#
install_iofogctl() {
    echoInfo "Attempting to install 'iofogctl'"

    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        install_iofogctl_linux
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        install_iofogctl_darwin
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        # POSIX compatibility layer and Linux environment emulation for Windows
        install_iofogctl_win
    elif [[ "$OSTYPE" == "msys" ]]; then
        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
        install_iofogctl_win
    elif [[ "$OSTYPE" == "win32" ]]; then
        # I'm not sure this can happen.
        install_iofogctl_win
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        install_iofogctl_linux
    else
        iofogctl_install_exit
    fi
}

#
# Check if iofogctl exists
#
check_iofogctl() {
    if  [[ -z "$(command -v iofogctl)" ]]; then
        echoInfo "iofogctl could not be found in the PATH. "
        read -p "Would you like to install iofogctl ? (y/n [y]) " INSTALL_IOFOGCTL
        INSTALL_IOFOGCTL=${INSTALL_IOFOGCTL:-"y"}
        if [[ "${INSTALL_IOFOGCTL}" = "y" ]]; then
            install_iofogctl
            if [[ -z "$(command -v iofogctl)" ]]; then
                echoError "iofogctl not found in PATH after installation"
                echoInfo "Please follow github instructions to install iofogctl: https://github.com/eclipse-iofog/iofogctl"
                exit 1
            fi
        else
            echoError "Missing dependency: iofogctl"
            printHelp
        fi
    else
        if [[ -z "$(iofogctl version | grep 1.3)" ]]; then
            echoError "iofogctl version 1.3.0 not found in your path."
            install_iofogctl
        else
            echoInfo " 'iofogctl' found successfully"
        fi
    fi
}

install_docker_error() {
    echoError "Could not automatically install docker."
    echoInfo "Please follow instructions at: ${DOCKER_INSTALL_URL}"
    exit 1
}

install_docker_apt() {
	sudo $1 update -qy
	sudo $1 install \
			apt-transport-https \
			ca-certificates \
			curl \
			gnupg2 \
			software-properties-common -qy
	DISTRO=$(lsb_release -a 2> /dev/null | grep 'Distributor ID' | awk '{print $3}')
	if [[ "$DISTRO" == "Ubuntu" ]]; then
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	else
		curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
	fi
	sudo $1 update -qy
	sudo $1 install docker-ce docker-ce-cli containerd.io -qy
}

install_docker_linux() {
	# install_docker_linux
	sleep 3
	curl -fsSL https://get.docker.com/ | sh
    # if [[ -x "$(command -v apt-get)" ]]; then
	# 		install_docker_apt "apt-get"
	# 	elif [[ -x "$(command -v apt)" ]]; then
	# 		install_docker_apt "apt"
    # elif [[ -x "$(command -v dnf)" ]]; then
    #     sudo dnf -y install dnf-plugins-core
    #     sudo dnf config-manager \
    #         --add-repo \
    #         https://download.docker.com/linux/fedora/docker-ce.repo
    #     sudo dnf install docker-ce docker-ce-cli containerd.io -y
    # elif [[ -x "$(command -v yum)" ]]; then
    #     sudo yum install -y yum-utils \
    #         device-mapper-persistent-data \
    #         lvm2 -qy
    #     sudo yum-config-manager \
    #         --add-repo \
    #         https://download.docker.com/linux/centos/docker-ce.repo
    #     sudo yum install docker-ce docker-ce-cli containerd.io -qy
    # else
    #     install_docker_error
    # fi
}

install_docker() {
    if [[ "$1" == "darwin" ]]; then
        {
            python -m webbrowser "${DOCKER_DARWIN_URL}"
        } || {
            xdg-open "${DOCKER_DARWIN_URL}"
        } || {
            open "${DOCKER_DARWIN_URL}"
        } || {
            echoInfo "Could not automatically install docker."
            echoInfo "Please follow instructions at: ${DOCKER_DARWIN_URL}"
        }
        read -p "Press any key when you are done with docker installation to continue bootstrapping ..." NOT_USED_INPUT
    elif [[ "$1" == "windows" ]]; then
        install_docker_error
    else
        install_docker_linux
    fi
}


check_docker() {
    if  [[ -z "$(command -v docker)" ]]; then
        echoInfo "'Docker' could not be found in the PATH."
        read -p "Would you like to install Docker ? (y/n [y]) " INSTALL_DOCKER
        INSTALL_DOCKER=${INSTALL_DOCKER:-"y"}
        if [[ "${INSTALL_DOCKER}" = "y" ]]; then
            if [[ "$OSTYPE" == "linux-gnu" ]]; then
                install_docker "linux"
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                # Mac OSX
                install_docker "darwin"
            elif [[ "$OSTYPE" == "cygwin" ]]; then
                # POSIX compatibility layer and Linux environment emulation for Windows
                install_docker "windows"
            elif [[ "$OSTYPE" == "msys" ]]; then
                # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
                install_docker "windows"
            elif [[ "$OSTYPE" == "win32" ]]; then
                # I'm not sure this can happen.
                install_docker "windows"
            elif [[ "$OSTYPE" == "freebsd"* ]]; then
                install_docker "linux"
            else            
                return 1
            fi
            if [[ -z "$(command -v docker)" ]]; then
                echoError " 'docker' not found in PATH after installation."
                install_docker_error
            fi
        else
            echoError "Missing dependency: Docker"
            printHelp
        fi
    else
        echoInfo " 'docker' found successfully"
    fi

}

# Is the user looking for help?
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    printHelp
fi

if  [[ -z "$(command -v curl)" ]]; then
    echoError " 'curl' not found, Please install and re-run bootstrap.sh."
    exit 1
fi

if [[ "$1" != "--ignore-checks" ]]; then
    echoInfo "Checking for dependencies.."
    check_iofogctl
    check_docker
fi

if [[ "$1" == "--destroy" ]]; then

    # Disconnect from iofogctl
    echoInfo "Disconnecting iofogctl from default namespace"
    iofogctl disconnect

    # Remove microservices containers
    echoInfo "Deleting iofog SDK docker containers"
    for microserviceContainer in "$(docker ps --filter 'name=iofog_' -aq)"
    do
        if [[ ! -z "$microserviceContainer" ]]; then
            docker stop ${microserviceContainer} && docker rm ${microserviceContainer}
        fi
    done

    # Remove iofog stack containers
    for ecnContainer in "$(docker ps --filter 'name=iofog-' -aq)"
    do
        if [[ ! -z "$ecnContainer" ]]; then
            docker stop ${ecnContainer} && docker rm ${ecnContainer}
        fi
    done

    echo
    echoSuccess "Successfully cleaned up local ioFog SDK stack."
else
    # Pulling latest images to avoid any fail with docker client inside iofogctl in Vagrant VMs
    echoInfo "Pulling ioFog docker images.."
    echoInfo "  iofog-controller"
    docker pull iofog/controller:1.3.0-beta > /dev/null 2>&1

    echoInfo "  iofog-agent"
    docker pull iofog/agent:1.3.0-beta > /dev/null 2>&1

    echoInfo "  iofog-connector"
    docker pull iofog/connector:1.3.0-beta > /dev/null 2>&1 

    echoInfo "Docker images pulled successfully."

    # Deploy using iofogctl
    echo
    echoInfo "Deploying local ioFog ECN"
    iofogctl deploy -f local-stack.yml
    ./status.sh
fi