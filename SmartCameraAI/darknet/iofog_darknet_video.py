#
# iofog Darknet Video is a wrapper around Darknet that we use to pull streaming data
# from a camera and push out results via iomessage for later
# micro services to be able to consume.
#

from ctypes import *
import os
import math
import random
import re
import base64
import sys
import yaml
import json
import requests

import numpy as np
import cv2
import time
import darknet

from iofog_python_sdk.client import IoFogClient, IoFogException
from iofog_python_sdk.iomessage import IoMessage
from iofog_python_sdk.listener import *

# These are our global data structures for Darknet to work
netMain = None
metaMain = None
altNames = None

ENCODING = 'utf-8'

# Attempt to get an iofog client
try:
    client = IoFogClient()
except IoFogException as e:
    # client creation failed, e contains description
    print(e)
    sys.exit(1)


#
# Convert coordinates from floats to ints
#
def convertBack(x, y, w, h):

    xmin = int(round(x - (w / 2)))
    xmax = int(round(x + (w / 2)))
    ymin = int(round(y - (h / 2)))
    ymax = int(round(y + (h / 2)))
    return xmin, ymin, xmax, ymax

#
# Draw bounding boxes on images
#
def cvDrawBoxes(detections, img):

    detection_locations = []
    for detection in detections:
        x, y, w, h = detection[2][0], \
                     detection[2][1], \
                     detection[2][2], \
                     detection[2][3]
        xmin, ymin, xmax, ymax = convertBack(
            float(x), float(y), float(w), float(h))
        pt1 = (xmin, ymin)
        pt2 = (xmax, ymax)
        cv2.rectangle(img, pt1, pt2, (0, 255, 0), 1)
        name = detection[0].decode()
        probability = round(detection[1] * 100, 2)
        probabilityString = str(probability)
        cv2.putText(img,
                    name +
                    " [" + probabilityString + "]",
                    (pt1[0], pt1[1] - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.5,
                    [0, 255, 0], 2)
        dict = {"name": name, "probability": probability, "corners": [pt1, pt2]}
        detection_locations.append(dict)
    return img, detection_locations


#
# Send data via the iomessage message bus for downstream
# microservices to consume.
#
def sendIOMessage(data, client, image):

    # Create a message
    url = "http://127.0.0.1:54321/v2/messages/new"
    headers = {'content-type': 'application/json'}

    base64_bytes = base64.b64encode(image)
    base64_string = base64_bytes.decode(ENCODING)
    content = {
        'detections': data,
        'image_b64': base64_string
    }

    base64_contentdata_bytes = base64.b64encode(json.dumps(content).encode())
    base64_contentdata_string = base64_contentdata_bytes.decode(ENCODING)

    body = {"publisher": client.id, "version": 4, "infotype": "json", "infoformat": "json",
                "contentdata":base64_contentdata_string}
    r = requests.post(url, data=json.dumps(body, indent=4), headers=headers, timeout=20)
    print(r)

#
# Load all the config from external config file
#
# Returns configPath, metaPath, weightPath as strings (if valid)
# Throws ValueError if there are any problems in loading config.
#
def loadConfig():

    # Get our config file from the local agent with a post request
    try:
        url = "http://127.0.0.1:54321/v2/config/get"
        headers = {}
        headers["Content-Type"] = 'application/json'
        headers['cache-control'] = 'no-cache'
        data = {}
        data["id"] = os.environ['SELFNAME']
        data = json.dumps(data, indent=4)
        r = requests.post(url, data=data, headers=headers )
        jsonResponse = json.loads(r.text)
        config = jsonResponse["config"]
        theConfig = eval(config) # We are given a string on the other end, we need to eval this to become a dict
    except requests.exceptions.RequestException as ex:
        # some error occurred, ex contains description
        print(ex)
        print("Reverting to default config")
        theConfig = {
            'configPath': "./cfg/yolov3.cfg",
            'weightPath': "./yolov3.weights",
            'metaPath': "./cfg/coco.data",
            'cameraSource': 0
        }

    # Read our the values we care about
    configPath  = theConfig['configPath']
    weightPath  = theConfig['weightPath']
    metaPath    = theConfig['metaPath']
    cameraSource   = theConfig['cameraSource']
    FPS = theConfig.get('FPS', 60)
    threshold = theConfig.get('treshold', 0.40)

    # Check that everything we need exists
    if not os.path.exists(configPath):
        raise ValueError("Invalid config path `" +
                         os.path.abspath(configPath) + "`")

    if not os.path.exists(weightPath):
        raise ValueError("Invalid weight path `" +
                         os.path.abspath(weightPath) + "`")

    if not os.path.exists(metaPath):
        raise ValueError("Invalid data file path `" +
                         os.path.abspath(metaPath) + "`")

    print(theConfig)

    return configPath, metaPath, weightPath, cameraSource, FPS, threshold


#
# This is the "main" method. Run YOLO over the camera input and run the
# target matching algorithms.
#
def YOLO():
    print("Starting YOLO...")

    # Make these global context
    global metaMain, netMain, altNames

    # Load our config
    configPath, metaPath, weightPath, cameraSource, FPS, threshold = loadConfig()

    # Instantiate our neural net for Darknet
    netMain = darknet.load_net_custom(configPath.encode(
        "ascii"), weightPath.encode("ascii"), 0, 1)  # batch size = 1

    # Load our meta data from external file
    metaMain = darknet.load_meta(metaPath.encode("ascii"))

    # Load our model labels
    try:
        with open(metaPath) as metaFH:
            print("Loading Models...")
            metaContents = metaFH.read()

            match = re.search("names *= *(.*)$", metaContents, re.IGNORECASE | re.MULTILINE)

            if match:
                result = match.group(1)
            else:
                result = None

            print("Loading Names List...")

            try:
                if os.path.exists(result):
                    with open(result) as namesFH:
                        namesList = namesFH.read().strip().split("\n")
                        altNames = [x.strip() for x in namesList]
            except TypeError:
                pass
    except Exception:
        pass

    print("Successfully loaded Config")

    # Set up our camera capture
    capture = cv2.VideoCapture(cameraSource)
    if not capture:
        print("Invalid Capture Device Given, defaulting to 0")
        capture = cv2.VideoCapture(0) #Default down to 0
        if not capture:
            print("No Capture Device found at given config or 0")
            raise ValueError("Invalid camera source")

    print("Starting Darknet capture...")

    # Create an image we reuse for each detect
    darknet_image = darknet.make_image(darknet.network_width(netMain),
                                       darknet.network_height(netMain), 3)
    nb_frame = FPS - 1
    nb_sec = 0
    while True:
        # Get the frame index
        nb_frame = (nb_frame + 1) % FPS
        print(f"starting loop: {nb_sec} seconds, frame idx: {nb_frame}")
        # Attempt to read a frame from the camera stream
        ret, frame_read = capture.read()

        # Only process the first frame of every second.
        if nb_frame != 0:
            continue
        else:
            nb_sec += 1

        # If BBB demo, skip 50 first seconds
        if cameraSource == "/opt/darknet/test_video_files/BBB.mp4" and nb_sec < 50:
            continue

        if not ret:
            print("Could not read a frame, skipping...")
            continue

        # Read the frame and turn it into color
        frame_rgb = cv2.cvtColor(frame_read, cv2.COLOR_BGR2RGB)

        # Resize the frame correctly
        frame_resized = cv2.resize(frame_rgb,
                                   (darknet.network_width(netMain),
                                    darknet.network_height(netMain)),
                                    interpolation=cv2.INTER_LINEAR)

        # Translate into darknet format
        darknet.copy_image_from_bytes(darknet_image, frame_resized.tobytes())

        # Detect on the image
        detections = darknet.detect_image(netMain, metaMain, darknet_image, thresh=threshold)

        # Draw boxes of the detections on the image
        image, detection_locations = cvDrawBoxes(detections, frame_resized)

        # Recolor the image
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)


        # Did we detect anything?
        if detection_locations:

            # This is sending a list of tuples of tuples, so to access you need to first access
            # the list with detection_locations[0], That will give you another tuple with two
            # entries, each a tuple
            # print(detection_locations)
            img = cv2.imencode(".png", image)[1]
            sendIOMessage(detection_locations, client, img)

        cv2.waitKey(3)

    capture.release()

#
# This is the main entry point
#
if __name__ == "__main__":
    print("Starting Darknet...")

    # Let 'er rip!
    YOLO()