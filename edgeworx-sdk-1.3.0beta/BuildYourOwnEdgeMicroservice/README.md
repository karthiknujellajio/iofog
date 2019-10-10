# Build your own edge microservice

This demo is meant to give you a quick start and get your hands dirty while building your own edge microservice.

We chose javascript, and React.js because it is a widely spread and known language and it will provide you with visual feedback.

The content of the `UI` folder has been created using `npx create-react-app`, which is the most used [tool](https://github.com/facebook/create-react-app) to bootstrap React applications.

# Just get it running

Prerequisite:

* You need a local ioFog stack running (You can get one by running the parent folder `./bootstrap` script).

Build and deploy your microservice:

Run: 
```
$> build.sh
$> iofogctl -v deploy application -f config.yml
```

Once the application is deployed, and that `iofogctl get all` shows a RUNNING status for `BYOEM-UI` microservice, `docker ps` should shows a `byoem-ui` container running, you can visit `localhost:3000` on your browser.

# What did just happened ?

`build.sh` does two things:

* It builds a local docker image tagged `byoem-ui:latest` from the `Dockerfile`
* It generates the content of `config.yml` used by iofogctl to deploy the application

The `Dockerfile` is self explanatory, but here is a quick run down if you are not familiar with docker, or React:

* It uses the publicly available base image `node:10` to start on a linux environment with nodejs and npm installed
* It creates a working folder `/app`
* It copies the `UI/package.json` file into the `/app` folder
* It installs the node_modules required by the app
* It copies over the folders `UI/src` and `UI/public` to `/app/src` and `/app/public`
* It tells docker that when the image is being run inside a container, the command to run is `npm start`

`npm start`, when used in a project bootstraped by `create-react-app`, will start the react application in dev mode, listening on port 3000

The `config.yml` that gets generated tells iofogctl how to deploy our new application:

* The application is called `BuildYourOwnEdgeMicroservice`
* The application is composed of one microservice called `BYOEM-UI`
* The microservice is to be run on the ioFog agent called `local-agent`
* The agent does not require any specific configuration
* The microservice code is in the docker image tagged `byoem-ui`, regardless of the agent type (x86, or ARM)
* The image is to be found locally on the agent (by opposition to be fetched from dockerhub)
* The microservice requires port forwarding on its container, from the host port 3000 to the container port 3000
* The microservice is to be rebuild if it already exists

`iofogctl deploy application -f config.yml` deploys the application described in the config.yml file onto your ioFog stack.

This will only work in the local ioFog set up, where the ioFog Agent is running inside a docker container on the same computer than the one building your microservice.
The local ioFog Agent shares the same docker socket than the computer it is running on, therefore it shares its local cache of images.
A section further down explains how to get your microservice to run on a remote ioFog Agent.

# How do I update the microservice ?

You can edit the React application like any other react application by editing the files located in `UI/src/`

Once you are satisfied with your changes and want to redeploy your updated version of your microservice you:
* Need to rebuild the image (either by directly running the `docker build` command, or by using the `build.sh` script)
* Need to delete your application by running `iofogctl delete application BuildYourOwnEdgeMicroservice`
* Need to instruct the ioFog Controller to redeploy your application: `iofogctl deploy application -f config.yml`

This will take up to a few minutes before your changes are visible as the ioFog Agent needs to be instructed to delete the container, then rebuild a new one.

Your changes should be visible once the status of your microservice displayed by `iofogctl get microservices` shows RUNNING again.

**NB**: The delete step is only necessary because we want our ioFog Agent to rebuild its container to use the newest image we just built. If you didn't update the docker image, and just want to change the microservice config, you can simply re run the deploy step without deleting first.

# How do I get my microservice to run on a remote ioFog Agent ?

For your remote ioFog Agent to be able to retrieve the microservice image, it needs to be publicly available on docker public repository: [Docker Hub](https://hub.docker.com/)

* Go ahead and create a Docker Hub account (it has a free tier) if you don't have one yet.
* Rebuild the microservice with a custom tag: `./build.sh <your_docker_username>/byoem-ui` OR `docker build -f Dockerfile -t <your_docker_username>/byoem-ui ./UI/`
* Log into docker using `docker login` and your Docker hub credentials
* Push your image using `docker push <your_docker_username>/byoem-ui`

To change the agent your microservice is running on, minors changes are required to the `config.yml` (Be mindful that each time you run `build.sh`, the `config.yml` gets overwritten. Consider running the `docker build` command by itself instead of `build.sh` once you have reached this section)

* Edit the agent name to match your remote agent name
* Edit the image for x86 and ARM to be `<your_docker_username>/byoem-ui`
* Edit the `images:registry` field from `local` to `remote`

Modifying the `images:registry` field to `remote` will instruct the ioFog Agent to fetch the microservice image from docker public repository Docker Hub.