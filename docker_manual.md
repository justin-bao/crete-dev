# Guide to Running CRETE with Docker

* [Prerequisites](#1-prerequisites)
	* [What is Docker?](#what-is-docker)
	* [Install Docker](#install-docker)
	* [Install Native QEMU](#install-native-qemu)
* [Running CRETE through Docker](#2-running-crete-through-docker)
	* [Pulling from Docker Hub](#pulling-from-docker-hub)
	* [Creating a CRETE Docker Container](#creating-a-crete-docker-container)
	* [Starting the Docker Container and Running CRETE](#starting-the-docker-container-and-running-crete)
* [Running the Tutorial on CRETE](#3-running-the-tutorial-on-crete)
	* [Image Location](#image-location)
	* [Ensuring QEMU is Stopped](#ensuring-qemu-is-stopped)
	* [Running crete-dispatch](#running-crete-dispatch)
	* [Running crete-vm-node](#running-crete-vm-node)
	* [Running crete-svm-node](#running-crete-svm-node)
* [Running an Executable on CRETE](#4-running-an-executable-on-crete)
	* [Copying the QEMU Image to the Host](#setting-up-the-test-on-the-guest-os)
	* [Copying the Executable to the QEMU Image](#copying-the-executable-to-the-qemu-image)
	* [Modifying the Configuration File](#modifying-the-configuration-file)
	* [Creating a New Snapshot](#creating-a-new-snapshot)

## 1. Prerequisites

The version of Docker used to test CRETE compatibility is Docker version 18.03.1-ce

### What is Docker?
Docker provides tools for deploying applications within containers separate from the host OS and other containers. As a result, the setup is quick and streamlined, and the container (along with any changes made within it) is discarded after use. Docker containers are built from a Docker image file.

### Install Docker

To utilize the CRETE Docker image, Docker must be installed on your machine. For Ubuntu installation, follow the instructions on the [Docker website](https://docs.docker.com/install/linux/docker-ee/ubuntu/)

The CRETE Docker image comes with a tutorial executable to be run in CRETE. To run a different executable, minor adjustments must be made to the configuration files and the QEMU image.

### Instal Native QEMU

CRETE requires a native version of QEMU 2.3. This can be downloaded and built by running the following:

```bash
$ wget https://download.qemu.org/qemu-2.3.0.tar.xz
$ tar xvJf qemu-2.3.0.tar.xz
$ cd qemu-2.3.0
$ ./configure
$ make
```

## 2. Running CRETE through Docker
### Pulling from Docker Hub

To pull the latest build of a particular Docker image, run:

```bash
docker pull nhaison/crete
```

Note that this process pulls images containing code compiled by a third-party service. We do not accept responsibility for the contents of the image.

### Creating a CRETE Docker Container

Now that you have a CRETE Docker image you can try creating a container named crete from the image.

```bash
docker run --name crete -ti --ulimit='stack=-1:-1' nhaison/crete
```

Note that the ```--ulimit``` option sets an unlimited stack size inside the container. This is to avoid stack overflow issues when running CRETE.

If this worked correctly, your shell prompt will have changed and you will be the root user. Verifying the user should yield the following output:

```bash
$ root@d62a2428405d:/home# whoami
$ root
$ root@d62a2428405d:/home# 
```

Now exit the container

```bash
root@d62a2428405d:/home# exit
```

### Starting the Docker Container and Running CRETE

Now enter the existing container
```bash
docker start -ai crete
```

The container can be accessed through multiple terminal windows by running:
```bash
docker exec -it crete bash
```

## 3. Running the Tutorial on CRETE

>### General flow of setup for Distributed Mode
>1. Make sure the image you created is found under vm-node/vm/1/ (vm-node/vm/1/crete.img)
>2. Boot the VM image using QEMU without kvm-enabled and sample configuration file to be tested. (crete.demo.echo.xml)
>3. Save the snapshot of the VM image as 'test'
>4. Using crete-qemu, boot the image with the snapshot. *Do not add option '-enable-kvm'. This will disable crete functionality because crete does not support KVM*
>5. Run crete-run and take a snapshot as the image begins waiting for a port 
```[CRETE] Waiting for port... ```
>6. Save the snapshot fo the VM image as 'test'
>7. Now you are ready to run ```crete-dispatch -c crete.dispatch.xml```, ```crete-vm-node -c crete.vm-node.xml``` (Run this command within vm-node folder), and ```crete-svm-node -c crete.svm-node.xml``` in seperate terminal windows

### Image Location
Make sure the image you created is under the correct directory. The path should look like this:
```xml 
crete/crete-dev/image_template/vm-node/vm/1/crete.img 
```

### Ensuring QEMU is Stopped

Before starting CRETE, ensure that QEMU is not currently running. To check, open a different terminal window and run the following:

```bash
telnet localhost 1234
$ q
enter
```

If the telnet command fails, QEMU is not running in the first place. Otherwise, there should now be no QEMU processes running.

### Running crete-dispatch

In a separate terminal window accessing the container, locate crete.dispatch.xml. It should be found under:
```xml 
/home/crete/crete-dev/image_template/crete.dispatch.xml
```

Make sure the path node in crete.dispatch.xml:
```xml 
<path>/home/crete/crete-dev/image_template/vm_node/vm/1/crete.img</path>
```
matches the path to your crete.img

Run 
```bash
cd /home/crete/crete-dev/image_template
crete-dispatch -c crete.dispatch.xml 
```

You should see:
```xml 
[CRETE] Awaiting connection on 'symdrive-svl.cs.pdx.edu' on port '10012' ...
```
This indicates you ran _crete-dispatch_ successfully and can now run _crete-vm-node_.

### Running crete-vm-node
In a separate terminal window accessing the container, locate crete.vm-node.xml. It should be found under:
```xml 
/home/crete/crete-dev/image_template/vm-node/crete.vm-node.xml 
```

Run 
```bash
cd /home/crete/crete-dev/image_template/vm-node/
crete-vm-node -c crete.vm-node.xml 
```
You should see:
```xml 
[CRETE] Connecting to master 'localhost' on port '10012' ...
reset()
entering: QemuFSM_
entering: Start
...
```
This indicates you ran _crete-vm-node_ successfully and can now run _crete-svm-node_.

### Running crete-svm-node
In a separate terminal window accessing the container, locate crete.svm-node.xml. It should be found under:
```xml
/home/crete/crete-dev/image_template/crete.svm-node.xml
```
Make sure the path node matches the path to your crete-klee-1.4.0
```xml
<path>
	<symbolic>/home/crete-build/bin/crete-klee-1.4.0</symbolic>
</path>
```
Run
```bash
cd /home/crete/crete-dev/image_template
crete-svm-node -c crete.svm-node.xml 
```

You should see:
```xml 
[CRETE] Connecting to master 'localhost' on port '10012' ...
entering: KleeFSM_
entering: Start
...
```

CRETE will then run many test cases to test the selected executable. This may take a couple of minutes to finish.

__You've successfully run CRETE in Distributed Mode!__

## 4. Running an Executable on CRETE

### Copying the QEMU Image to the Host

The executable to be tested must be put onto the QEMU image. To copy the image from the running Docker container, use the host OS to run:

```bash
docker cp <id_of_container>:home/crete/image_template/vm-node/vm/1/crete.img <destination_path>/crete.img
```

However, CRETE needs the executable to be tested and a configuration file in order to function. To start QEMU with this image, navigate to the directory of the image and run:

```bash
$ qemu-system-x86_64 -hda crete.img -m 256 -k en-us
```

The user set up in this OS has the following credentials:

> Username: __crete__
>
> Password: __crete__

### Copying the Executable to the QEMU Image

From within the guest OS of the QEMU image, run:

```bash
$ scp -r <host-user-name>@10.0.2.2:</path/of/executable/in/host> .
```

in order to copy the executable to the guest OS.

### Modifying the Configuration File

From within the guest OS, the configuration file for CRETE needs to be modified very slightly to accommodate the new executable. The node

```xml
<exec>path/to/executable</exec>
```

must be modified to reflect the path to the new executable.

### Creating a New Snapshot

Now that we have modified the guest OS, CRETE needs a new snapshot to run properly. The QEMU menu should be accessible through _ctrl+alt+2_ - however, if this doesn't work, run QEMU with the option:

```bash
-monitor telnet:127.0.0.1:1234,server,nowait
```

and pull up the menu from the host OS by running:

```bash
$ telnet 127.0.0.1 1234
```

Once in the menu for QEMU, run the following to save a snapshot entitled "test":

```bash
$ savevm test
enter
$ q
enter
```

### Copying the QEMU Image Back to the Container

Move the newly modified QEMU image back into the running container by using the host to run:

```bash
docker cp <path_of_crete.img> <id_of_container>:home/crete/image_template/vm-node/vm/1/crete.img
```

__Now, you can follow the same steps as in__ [Section 3](#3-running-the-tutorial-on-crete) __to run CRETE with the new executable!__
