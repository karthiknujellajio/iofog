#!/usr/bin/env bash
#
# bootstrap.sh will configure an iofog Demo repo to use the local EAP packages.
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
usage() {
    echo
    echoInfo "Usage: `basename $0` [-h, --help] [--destroy]"
    echoInfo "$0 will deploy a local iofog stack using docker containers."
    echoInfo "--destroy will remove any existing local iofog stack."
    exit 0
}

#
# Check between apt or yum
#
install_iofogctl_linux() {
    if ! [ -x "$(command -v curl)" ]; then
        echoError " 'curl' not found, Please install and re-run bootstrap.sh."
        exit 1
    fi
    if [ -x "$(command -v apt-get)" ]; then
        curl -s https://packagecloud.io/install/repositories/iofog/iofogctl/script.deb.sh | sudo bash
        sudo apt-get install iofogctl -y
    elif [ -x "$(command -v apt)" ]; then
        curl -s https://packagecloud.io/install/repositories/iofog/iofogctl/script.deb.sh | sudo bash
        sudo apt install iofogctl -y
    elif [ -x "$(command -v yum)" ]; then
        curl -s https://packagecloud.io/install/repositories/iofog/iofogctl/script.rpm.sh | sudo bash
        sudo yum install iofogctl -y
    else
        iofogctl_install_exit
    fi
}

install_iofogctl_win() {
    echoInfo "We do not currently support Windows"
    exit 1
}

install_iofogctl_darwin() {
    if [ -x "$(command -v brew)" ]; then
        brew tap eclipse-iofog/iofogctl
        brew install iofogctl
    else
        echoInfo "'brew' not found, please install and re-run bootstrap.sh"
        iofogctl_install_exit
    fi
}

iofogctl_install_exit() {
    echoInfo "Could not detect package installation system"
    echoInfo "Please follow github instructions to install iofogctl: https://github.com/eclipse-iofog/iofogctl"
    exit 1
}

#
# Install iofogctl
#
install_iofogctl() {
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
            usage
        fi
    else
        echoInfo " iofogctl found successfully"
    fi
}

install_docker_error() {
    echoError "Could not automatically install docker"
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
            echoInfo "Could not automatically install docker"
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
        echoInfo "'Docker' could not be found in the PATH. "
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
            usage
        fi
    else
        echoInfo " 'Docker' found successfully"
    fi

}

#
# Check for python, install if it does not exists
#
check_python() {
    if [[ -z "$(command -v python3)" ]]; then
        echoInfo "No suitable python version found, installing python 3.6"
        install_python
    elif [[ "$(python3 --version)" == *"3.6"* ]] || [[ "$(python3 --version)" == *"3.7"* ]]; then
        echoInfo "$(python3 --version)"
        echoInfo " python already installed"
    else
        echoInfo "$(python3 --version)"
        echoInfo "python version mismatch, installing python 3.6"
        install_python
    fi
}

install_python() {
    read -p "Would you like to install Python3.6 ? (y/n [y]) " INSTALL_PYTHON
    INSTALL_PYTHON=${INSTALL_PYTHON:-"y"}
    if [[ "${INSTALL_PYTHON}" = "y" ]]; then
        echoInfo "installing python dependencies..."
        if [[ -x "$(command -v apt-get)" ]]; then
            apt-get update -y -q --force-yes
            apt-get install -y -q --force-yes build-essential zlib1g-dev libffi-dev libssl-dev openssl
        elif [[ -x "$(command -v yum)" ]]; then
            yum install -y -q gcc libffi-devel  zlib zlib-devel openssl openssl-devel
        elif [ -x "$(command -v brew)" ]; then
            brew install python3
        else
            echoError "Unable to install python 3.6, please install manually"
            exit 1
        fi

        echoInfo "installing python 3.6.9 and virtual environment"
        mkdir /python && cd /python
        curl https://www.python.org/ftp/python/3.6.9/Python-3.6.9.tgz | tar zx
        cd Python-3.6.9/
        ./configure && make && make install && cd ..
    else
        echoError "Missing dependency: Python"
        usage
    fi
}

# Is the user looking for help?
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
fi


if  [[ -z "$(command -v curl)" ]]; then
    echoError " 'curl' not found"
    exit 1
fi

if [[ "$1" != "--ignore-checks" ]]; then
    check_python
    check_iofogctl
    check_docker
fi

/usr/local/bin/pip3 install virtualenv
echoInfo "creating virtual environment called `env` and activating it"
/usr/local/bin/virtualenv ~/env
source ~/env/bin/activate

if [[ "$1" == "--destroy" ]]; then
    # Disconnect from iofogctl
    echoInfo "Disconnecting from iofogctl"
    iofogctl disconnect

    echoInfo "Deleting docker containers"
    # Remove microservices containers
    for microserviceContainer in "$(docker ps --filter 'name=iofog_' -aq)"
    do
        if [ ! -z "$microserviceContainer" ]; then
            docker stop $microserviceContainer && docker rm $microserviceContainer
        fi
    done
    # Remove iofog stack containers
    for ecnContainer in "$(docker ps --filter 'name=iofog-' -aq)"
    do
        if [ ! -z "$ecnContainer" ]; then
            docker stop $ecnContainer && docker rm $ecnContainer
        fi
    done
else
    iofogctl deploy -f local-stack.yml
fi