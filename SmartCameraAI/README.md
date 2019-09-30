# Smart Camera AI

SmartCameraAI is a demonstration of an edge microservice running an AI detection model using OpenCV, Darknet and YOLO 
on a streaming video source, extracting out the detected objects and forwarding that information onto a consuming micro 
service using IOMessage. The second microservice stores the last 20 frames and displays the detection data through in 
a simple node.js web application. 

You can run this demo on both `x86_64` and `aarch64` platforms. Additionally, if you have an edge device that contains a 
GPU, the AI detection processing can be run on the GPU to hugely improve performance. As an example, a representative 
edge device would be something like an Nvidia Jetson TX2. Images for each of these configurations are available from
the Edgeworx DockerHub repository.

## Requirements

Before running the script you must:
 * Have an ioFog deployment with at least one agent, one controller and one connector
    * IoFog Controller version >= 1.1.0 (`iofog-controller controller version`)
    * IoFog Connector version >= 1.1.0 (`iofog-connector version`)
    * IoFog Agent version >= 1.1.0  (`iofog-agent version`)
 * Have a user registered on the controller
 * Edit the config file: `config.yml`
  
    ```
    user:
      email: <USER_EMAIL>
      password: <USER_PASSWORD>
    ```
    ```
    controller:
      address: <CONTROLLER_API_IP_ADDRESS>[:<CONTROLLER_API_PORT>]
    ```
    ```
    microservices:
      video:
        fog-name: <VIDEO_AGENT_NAME>
        name: <VIDEO_MICROSERVICE_NAME> # If you are happy with the default name, you don't need to edit.
        ...
        config:
          ...
          cameraSource: <VIDEO_INPUT_ADDRESS> # This will be opened as an OpenCV Capture. It supports all standard video stream protocols (RTMP, RTSP, etc.).
      ui:
        fog-name: <UI_AGENT_NAME> # Both microservices may run on the same agent without any issue.
        name: <UI_MICROSERVICE_NAME> # If you are happy with the default name, you don't need to edit.
      ports:
        - external: 8080 # You will be able to access the ui on <AGENT_IP>:8080
          internal: 80 # The ui is listening on port 80. Do not edit this.
          publicMode: false # Do not edit this.
        ...
    ```
    ```
    routes:
      - from: <VIDEO_MICROSERVICE_NAME> # If you are happy with the default name, you don't need to edit.
        to: <UI_MICROSERVICE_NAME> # If you are happy with the default name, you don't need to edit.
    ```

### Camera source

The camera source will be opened with python `cv2.VideoCapture(<cameraSource>)`. You can find examples 
[here](https://www.programcreek.com/python/example/85663/cv2.VideoCapture) and 
[here](https://opencv-python-tutroals.readthedocs.io/en/latest/py_tutorials/py_gui/py_video_display/py_video_display.html).

You can specify video streams URLs (e.g. RTMP, RTSP), or your usb video device (e.g. `0`  - which OpenCv will try to 
resolve as the default video capture device of the node running the agent), a video file (don't forget to add volume 
mapping in `config.yml` if you want to read from a file), and much more. See OpenCV documentation for full details.

If you are running on a Tegra Nvidia Device, such as the TX2 Development Kit or any hardware leveraging the module, 
the following string should be used for a cameraSource to access the onboard camera

```
nvcamerasrc ! video/x-raw(memory:NVMM), width=(int)1280, height=(int)720,format=(string)I420, framerate=(fraction)30/1 ! nvvidconv flip-method=0 ! video/x-raw, format=(string)BGRx ! videoconvert ! video/x-raw, format=(string)BGR ! appsink
```

This is the current standard for accessing video streams from onboard cameras connected to TX2 Devices. 

The video service can take a few minutes to initialize. You can access the UI microservice by pointing a web browser 
to http://localhost:8080 or to `<AGENT_IP>:<EXTERNAL_PORT>` (if you changed the config file). **Note**: this port will 
ONLY work if you have updated to the EAP packages. Otherwise, it is not exported by older versions of iofogAgent.

#### Demo files

The microservice container also comes with an embbeded test video (Big Buck Bunny) located at 
`/opt/darknet/test_video_files/BBB.mp4`

This can be used by editing the `config.yml` file and setting the `cameraSource` to 
`/opt/darknet/test_video_files/BBB.mp4` (Or you can start this demo using the `config_BBB.yml`)

```sh
../install.sh config_BBB.yml
```

## Available configs

* `config.yml`: Standard config, running on CPU, with cameraSource set as the default video input of the host device (0)
* `config_BBB.yml`: Premade config using local video file as camera source
* `config_awsdeeplens.yml`: Premade config using AWS Deep Lens camera source (with proper volume mapping)
* `config_GPU.yml`: Premade config that fetches the images that leverage the host GPU to run Darknet.

## Disclaimer

This script will FAIL if:
 * The Controller API is unreachable (HTTP requests will be made on the address provided in the yaml file)
 * Your user is not registered with the Controller (i.e. Does NOT show when running `iofog-controller user list` on 
 the iofog-controller).
 * The agent(s) specified by the `agent-name` value in the config.yml do not match those registered with the controller or
 are not provisioned correctly (i.e do NOT show when running `iofog-controller iofog list` on the controller)
 * Either one of the microservice names is already registered with the controller's catalog (i.e: 
 `iofog-controller catalog list` on the controller shows an entry with one of the microservice name)

## Known Issues

You might run into this in the logs of the UI web service:

```
> MessageWebServer@1.0.0 start /src
> node messageweb.js

[Wed May 29 2019 09:16:38] [LOG]   STERR :
 ping: bad address 'iofog'

[Wed May 29 2019 09:16:38] [LOG]   ERROR :
 { Error: Command failed: ping -c 3 iofog
ping: bad address 'iofog'

    at ChildProcess.exithandler (child_process.js:281:12)
    at emitTwo (events.js:126:13)
    at ChildProcess.emit (events.js:214:7)
    at maybeClose (internal/child_process.js:915:16)
    at Process.ChildProcess._handle.onexit (internal/child_process.js:209:5) killed: false, code: 1, signal: null, cmd: 'ping -c 3 iofog' }
[Wed May 29 2019 09:16:38] [WARN]  Host: 'iofog' is not reachable. Changing to '127.0.0.1'
```

This is the ioFog NodeJS SDK trying to ping the 'iofog' hostname by default. If it doesn't work, it falls back to 
trying to reach the agent on 127.0.0.1. In itself, this is not a problem for the UI microservice to work, as long
as there is proper networking configured.