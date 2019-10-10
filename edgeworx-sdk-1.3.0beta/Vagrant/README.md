# Why Vagrant

As stated in their [introduction](https://www.vagrantup.com/intro/index.html):
> Vagrant is a tool for building and managing virtual machine environments in a single workflow

We use Vagrant to describe the VM configuration and provisioning process through a simple configuration file called `Vagrantfile` while leaving you the choice of your favorite VM provider (VirtualBox, VMWare, etc, etc.)

# Installation

In order to install Vagrant, please download the [installation package](https://www.vagrantup.com/downloads.html).

This will install Vagrant and make the `vagrant` command available in your terminal. 

If you encounter any issue please refer to the [installation page]()

> Using Windows and VirtualBox ? Please read [this](https://www.vagrantup.com/docs/installation/#windows-virtualbox-and-hyper-v)

# Set up

## Configuring your VM provider
Vagrant support `VirtualBox`, `Hyper-V` and `Docker` out-of-the box. If you wish to use any of these (make sure they are installed on your computer), you don't need to do anything.

For the purpose of the ioFog SDK Demos, `VirtualBox` is sufficient and has been tested.

If you wish to use another provider (I.E: VMWare), you will need to tell Vagrant which VM provider you wish to use it with.
Please visit the [Providers page](https://www.vagrantup.com/docs/providers/) and follow the instructions from there to set up your provider.

## Managing the VM

To start the VM, please run:
```
vagrant up
```
The `vagrant up` step might take a few minutes to complete, this builds your VM and install the required tools.

To ssh into the started VM, please run:
```
vagrant ssh
```
After running `vagrant ssh` you will be ssh'd into the VM.

All the demos materials will be located into `$HOME/demo-sdk`. From there, you'll need to follow the `Getting Started` instructions from the root README.

The VM `$HOME/demo-sdk` and your local `ioFog SDK` folder (parent folder) are synchronized. Any change made on one side, will be reproduced on the other. Which allows you to edit anything you need or want using your favorite IDE, on your local computer, and have the changes automatically reflected to your Vagrant VM.


To stop/destroy the VM, please run:
```
vagrant destroy
```

### Note

The VM has been pre-configured with all the port mapping needed for the default configuration of the ioFog SDK Demos.

If you were to edit those port mapping in one of the demo `config.yml`, you will need to edit the `Vagrantfile` accordingly then destroy and rebuild the Vagrant VM.

Example:

HealthcareWearable demo is configured with a port mapping making its UI accessible on port localhost:5000

HealthcareWearable/config.yaml:
```
  ports:
    # The ui will be listening on port 80 (internal).
    - external: 5000 # You will be able to access the ui on <AGENT_IP>:5000
      internal: 80 # The ui is listening on port 80. Do not edit this.
```

Vagrantfile:
```
  # Port forwarding for Healthcarewearable UI
  config.vm.network "forwarded_port", guest: 5000, host: 5000, autocorrect: true
```
