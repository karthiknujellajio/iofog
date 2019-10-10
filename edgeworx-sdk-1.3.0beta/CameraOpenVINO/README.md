# OpenVINO AI Demo - Streaming Object Recognition from a Raspberry Pi Camera

This demo showcases the processing power of the Intel Neural Compute Stick 2 with a Raspberry Pi 3 B+ board and
a Raspberry Pi camera. It uses Intel OpenVINO for the real-time AI.

## Requirements

Before running the script you must:
 * Have an ioFog deployment with at least one agent, one controller and one connector
    * IoFog Controller version >= 1.1.0 (`iofog-controller controller version`)
    * IoFog Connector version >= 1.1.0 (`iofog-connector version`)
    * IoFog Agent version >= 1.1.0  (`iofog-agent version`)
 * Have a user registered on the controller
 
The default values are "true" and "Anonymous Person" for the config so you will get that if you don't set the config.

### Viewing the image AI output

Once the Demo is running, the images with object recognition bounding boxes can be viewed by connecting to the
web UI micro service. You will be able to access the viewer on `<AGENT_IP>:8080`.
