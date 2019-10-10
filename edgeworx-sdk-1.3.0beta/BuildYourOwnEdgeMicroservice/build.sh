#!/usr/bin/env bash
cd "$(dirname "$0")"

IMAGE=${1:-byoem-ui}

echo "Building the docker image..."

# Build the docker image
docker build -t "$IMAGE" -f Dockerfile ./UI/

echo "Docker image built !"
echo "Writing iofogctl config file..."

# Write the config.yml file with the proper image name
echo "---
name: BuildYourOwnEdgeMicroservice
microservices:
- name: BYOEM-UI
  agent:
    name: 'local-agent'
    config: {}
  images:
    arm: ${IMAGE}
    x86: ${IMAGE}
    # For the purpose of the demo, the image is built locally and shared with the docker engine of the ioFog agent
    # Registry local instructs the agent to look for a local image
    # Registry remote instructs the agent to look for a public image to pull from dockerhub
    registry: local
  ports:
  # The docker image starts the app in dev mode, which listen on port 3000.
  # This forwards the docker container port 3000 to the host port 3000
  - external: 3000
    internal: 3000" > config.yml

echo "iofogctl application config file written !" 