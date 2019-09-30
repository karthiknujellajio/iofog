ARG TAG_NAME=latest
FROM edgeworx/iofog-darknet-built:${TAG_NAME}

WORKDIR /opt/darknet

# iofog sdk needs this
RUN apt-get update && apt-get install -y \
    inetutils-ping

# Install our python sdk and deps
RUN pip3 install pyyaml ws4py iofog-python-sdk requests

# Add our app specific files
COPY start.sh start.sh
COPY script.sh script.sh
COPY iofog_darknet_video.py iofog_darknet_video.py

# Add demo videos
COPY test_video_files /opt/darknet/test_video_files

ENTRYPOINT ["bash", "start.sh"]