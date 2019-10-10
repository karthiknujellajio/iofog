#!/usr/bin/env sh

# Figure out what OS we are on
ARCH="$(uname -m)"

# Login to our docker hub repo
#docker login --username=edgeworx --email=

# Tag our image
docker tag edgeworx/iofog-video xaoc000/iofog-video

# Push to our DH account
docker push xaoc000/iofog-video