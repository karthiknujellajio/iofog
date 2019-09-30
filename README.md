# Edgeworx ioFog SDK

Welcome to the Edgeworx iofog SDK! You will find in here a quick and easy way to setup your a local ioFog stack using 
Docker containers and a set of demonstration applications that highlight real world use cases we are seeing in the wild. 

This archive contains the following content

```
edgeworx-iofog-sdk
    README.md                                           (this file)
    bootstrap.sh                                        # Checks for dependencies and create / destroy your local ioFog stack
    install.sh                                          # Installer for the demos 
    uninstall.sh                                        # Uninstaller for the demos
    local-stack.yml                                     # Configuration of a local ioFog ECN
    start/stop/status.sh                                # Utility files for starting and stoping your local iofog ECN
    CameraOpenVINO                                      # A Intel OpenVINO real-time AI on video feeds
        README.md
        ...
    SmartCameraAI                                       # A SmartCamera demo that runs AI on video feeds
        README.md
        ...
    HealthcareWearables                                 # A Healthcare demo that pulls data from a wearable monitor 
        README.md
        ...
    scripts                                             # A set of utilities that are used by the demos 
    python_helpers
    
```
### Getting Started

Firstly, you'll want to spin up your local ioFog stack. To do so, you can 
install the ioFog Demo environment using the `bootstrap.sh` script provided at the root level.

From there, you can browse each Demo app and its source code. You can use the `install.sh` script to install onto 
your iofog Edge Cloud Network (ECN). Each demo contains a `config.yml` that describes the application. Feel free to 
edit to match your environment or use as-is.

#### Bootstrapping the ECN

##### Compatibility
- iofogctl v1.2.1
- python v3.6, v3.7

The `bootstrap.sh` script requires and uses the `iofogctl` Command Line Interpreter (CLI) to create and run a 
Controller, a Connector and an Agent locally using [Docker](https://docs.docker.com/).

Script Usage:

```sh
./boostrap.sh [-h] [--destroy]
    --destroy option will attemp to delete your local ioFog stack and all remaining iofog related containers.
```

Bootstrap will use the configuration found in `local-stack.yml` to create your local ECN. Feel free to make changes
there if needed, or use as-is. 

#### Managing your ECN

If you started your ECN using the `bootstrap.sh` script, it is now automatically connected to your iofogctl CLI.
You can therefore use it to view and manage your ECN.

Try `iofogctl get all` for a text view of your ECN.

You will find all available commands using: `iofogctl --help` and `iofogctl [command] --help` or on 
our [website](https://iofog.org/)

#### Starting and Stopping your ECN

Once you have successfully bootstrapped your local ECN you may want to shut it down, without actually destroying it. 
You can do this by running:

```
./stop.sh 
```

When you're ready to come back and play, you can start up again with:
```
./start.sh 
```

And if you are interested in viewing all of the ECN containers running locally you can check the status with:

```
./status.sh 
```

### Installation of Demo Apps

Script Usage

```
./install.sh <path-to-demo-config.yml>
```

The `install.sh` script will use the ioFog REST APIs to set up and deploy the configuration described in `config.yml`. 
Docker images are all pulled from DockerHub. It will also output informational logging for you to see the sequence of 
REST calls that need to be made, and the response data.

Complete Example:

```sh
# Launch the SmartCameraAI Demo app
./install.sh SmartCameraAI/config.yml
```

Installation is completed when you see `You are done!`

### Next steps

Once deployed, it might take a few minutes to pull the docker images onto the iofog agent. If you have ssh access to 
the agent, you can ssh in the agent to:

* run `docker images` to know when it will be done pulling the images
* run `docker ps` once the images are pulled to check if the containers are running
* run `docker logs <CONTAINER_NAME>` to see the container logs

### Update

If you want to update the deployed Demos, you can update the config of the Microservices by editing the config
sections in your `config.yml` file and then re-run `./install.sh <path-to-config.yml>`. 

*WARNING*: ioFog uses the name of objects as a unique identifier. So if you want to update the name of your
microservice or agent (for example), you should make sure you tear down your existing setup first.

To update the process in this case is the following:

1. Run `./uninstall.sh <path-to-config.yml>`
2. Edit `config.yml` with new values
3. Run `./install.sh <path-to-config.yml>` again

### Tear Down

If you want tear down your setup, then you can simply run: 

```
./uninstall.sh <path-to-config.yml>
```

The `uninstall.sh` script removes all associated resources (microservices, catalog items, routes, flows, etc) from
your Controller and ECN that are specified in `config.yml`.

**WARNING: You MUST run `uninstall.sh` BEFORE editing `config.yml` to ensure the names used to clean 
are the same as the ones that were used to deploy in the first place.**

If you are new to ioFog and all this sounds crazy, you may want to run through our 
[Demo Tutorial](https://iofog.org/docs/1.0.0/tutorial/introduction.html "ioFog Tutorial") first. 

### Reporting Issues

If you happen to run into a problem with anything in the SDK, please post your issue or question in the [ioFog 
community forum](https://discuss.iofog.org/) where a member of the ioFog development team will be happy to help. As 
always REAL data and logs can help expedite that process ;)