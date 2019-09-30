#!/usr/bin/env sh

ARCH=$(uname -m)
ARCH_TAG=${ARCH}

VOLUMES=""
if type nvcc &> /dev/null; then
    echo "Building with GPU Volumes"
    VOLUMES="--volume=/usr/:/usr/ --volume=/lib/:/lib/"
    ARCH_TAG=${ARCH}_GPU
else
    echo "Building Without GPU"
fi

export ARCH=${ARCH}

# Build our base Docker image
echo "Building our base OpenCV image"
docker build -t edgeworx/iofog-opencv:${ARCH_TAG} -f docker/${ARCH}/Dockerfile.opencv .

# Build our intermediate darknet image
echo "Building our Darknet image"
docker build --build-arg TAG_NAME=${ARCH_TAG} -t edgeworx/iofog-darknet:${ARCH_TAG} -f docker/${ARCH}/Dockerfile.darknet .

echo "Running Darknet image to build Darknet"
CONTAINER_ID=$(docker run -d --privileged ${VOLUMES} edgeworx/iofog-darknet:${ARCH_TAG})

echo "=======Sleeping for 120 seconds========"
sleep 120

echo "Commiting ${CONTAINER_ID}"
docker commit ${CONTAINER_ID} edgeworx/iofog-darknet-built:${ARCH_TAG}

echo "Shutting down ${CONTAINER_ID}"
docker stop ${CONTAINER_ID}

echo "Building final App image"
if [ ! -f "./test_video_files/BBB.mp4" ]; then
    echo "Downloading Big Buck Bunny video"
    wget -O ./test_video_files/BBB.mp4 http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_60fps_normal.mp4
fi
docker build --build-arg TAG_NAME=${ARCH_TAG} -t edgeworx/iofog-video:${ARCH_TAG} -f docker/${ARCH}/Dockerfile .