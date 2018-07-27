# CRETE User Guide

[![Build Status](https://travis-ci.org/SVL-PSU/crete-dev.svg?branch=master)](https://travis-ci.org/SVL-PSU/crete-dev)

# Table of Contents

* [Prerequisites](#1-prerequisites)
	* [Terminology](#11-terminology)
	* [Unix/Linux Knowledge](#12-unix/linux-knowledge)
	* [Operating System](#13-operating-system)
* [Building CRETE](#2-building-crete)
	* [Building CRETE with Docker](#21-building-crete-with-docker)
		* [Install Docker](#install-docker)
		* [Pulling from Docker Hub](#pulling-from-docker-hub)
		* [Creating a CRETE Docker container](#creating-a-crete-docker-container)
	* [Building CRETE Locally](#22-building-crete-locally)
		* [Dependencies](#dependencies)
		* [Building](#building)
		* [Miscellaneous Setup](#miscellaneous-setup)
* [Preparing the Guest Operating System](#3-preparing-the-guest-operating-system)
	* [Create a QEMU Image](#31-create-a-qemu-image)
	* [Install the Guest OS](#32-install-the-guest-os)
	* [Boot the OS](#33-boot-the-os)
	* [Build CRETE Guest Utilities](#34-build-crete-guest-utilities)
	* [Other Guest OS Configurations](#35-other-guest-os-configurations)
* [Generating Test Cases for Linux Binaries](#4-generating-test-cases-for-linux-binaries)
	* [Setting Up the Test on the Guest OS](#41-setting-up-the-test-on-the-guest-os)
	* [Running CRETE in Distributed Mode](#42-running-crete-in-distributed-mode)
		* [Running crete-dispatch](#running-crete-dispatch)
		* [Running crete-vm-node](#running-crete-vm-node)
		* [Running crete-svm-node](#running-crete-svm-node)
	* [Running CRETE in Developer Mode](#43-executing-crete-front-end-on-guest-os-and-back-end-on-the-host-os-developer-mode)
		* [Running crete-dispatch](#running-crete-dispatch)
		* [Running crete-vm-node](#running-crete-vm-node)
		* [Running crete-svm-node](#running-crete-svm-node)
	* [Collecting Results on the Host OS](#44-collecting-results-on-the-host-os)
* [Configuration Options](#5-configuration-options)
	* [Running Distributed Mode](#running-distributed-mode)
* [FAQ](#6-faq)

## 1. Prerequisites
### 1.1. Terminology
Virtual Machine (VM)
>The VM is what runs the guest OS. Its purpose is to emulate a physical
machine.

Host Operating System (host OS)
> The _host OS_ is the primary OS where CRETE will be built, installed and executed from.

Guest Operating System (guest OS)
> The _guest OS_ is the OS that runs on the virtual machine.

### 1.2. Unix/Linux Knowledge
A modest familiarity with Unix-style systems is required. You must be able to
make your way around the system in a terminal and interact with files from
command line.

### 1.3. Operating System

CRETE requires the use of [Ubuntu
12.04-amd64](http://releases.ubuntu.com/12.04/ubuntu-12.04.5-desktop-amd64.iso)
or [Ubuntu
14.04-amd64](http://releases.ubuntu.com/14.04/ubuntu-14.04.5-desktop-amd64.iso)
for the host OS. While various guest OS should work, only
[Ubuntu-12.04.5-server-i386](http://releases.ubuntu.com/12.04/ubuntu-12.04.5-server-i386.iso),
[Ubuntu-12.04.5-server-amd64](http://releases.ubuntu.com/12.04/ubuntu-12.04.5-server-amd64.iso),
[Ubuntu-14.04.5-server-amd64](http://releases.ubuntu.com/14.04/ubuntu-14.04.5-server-amd64.iso),
and [Debian-7.11.0-i386](http://cdimage.debian.org/cdimage/archive/7.11.0/i386/iso-cd/debian-7.11.0-i386-netinst.iso)
have been tested.

## 2. Building CRETE

You can build CRETE Distributed using Docker or manually from source code. For manual installation, please skip this section.

### 2.1 Building CRETE with Docker

The version of Docker used to test CRETE compatibility is Docker version 18.03.1-ce

#### What is Docker?
Docker provides tools for deploying applications within containers separate from the host OS and other containers. As a result, the setup is quick and streamlined, and the container (along with any changes made within it) is discarded after use. Docker containers are built from a Docker image file.

#### Install Docker

To utilize the CRETE Docker image, Docker must be installed on your machine. For Ubuntu installation, follow the instructions on the [Docker website](https://docs.docker.com/install/linux/docker-ee/ubuntu/)

#### Pulling from Docker Hub

To pull down the latest build of a particular Docker image, run:

```bash
docker pull nhaison/crete
```

Note that this process pulls images containing code compiled by a third-party service. We do not accept responsibility for the contents of the image.

#### Creating a CRETE Docker container

Now that you have a CRETE Docker image you can try creating a container named crete from the image.

```bash
docker run --name crete -ti --ulimit='stack=-1:-1' nhaison/crete
```

Note that the ```--ulimit``` option sets an unlimited stack size inside the container. This is to avoid stack overflow issues when running CRETE.

If this worked correctly, your shell prompt will have changed and you will be the root user. Verifying the user should yield the following output:

```bash
root@d62a2428405d:/home# whoami
root
root@d62a2428405d:/home# 
```

Now exit the container

```bash
root@d62a2428405d:/home# exit
```

#### Starting the Docker container and running CRETE

Now enter the existing container
```bash
docker start -ai crete
```

The container can be accessed through any terminal window:
```bash
docker exec -it crete bash
```

__Skip to section 4.2 for further instructions in running CRETE in Distributed mode. The rest of the manual until then details how to build CRETE on the host OS.__


### 2.2 Building CRETE Locally

#### Dependencies

The following apt-get packages are required:
```bash
sudo apt-get update
sudo apt-get install build-essential libcap-dev flex bison cmake libelf-dev git libtool libpixman-1-dev minisat zlib1g-dev libglib2.0-dev
```

LLVM 3.4 is also required to build CRETE, and the LLVM packages provided by LLVM
itself is recommended. Please check [LLVM Package
Repository](http://apt.llvm.org/) for details. For the recent Ubuntu (≥ 12.04
and ≤ 15.10, e.g. 14.04 LTS) or Debian, please use the following instructions to
install LLVM 3.4:
```bash
echo "deb http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.4 main" | sudo tee -a /etc/apt/sources.list
echo "deb-src http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.4 main" | sudo tee -a /etc/apt/sources.list
wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key|sudo apt-key add -
sudo apt-get update
sudo apt-get install clang-3.4 llvm-3.4 llvm-3.4-dev llvm-3.4-tools
```

#### Building
>#### Warning
>
> CRETE uses Boost 1.59.0. If any other version of Boost is installed on the system, there may be conflicts. It is recommended that you remove any conflicting Boost versions.
>
>#### Note
> CRETE requires a C++11 compatible compiler.
> We recommend clang++-3.4 or g++-4.9 or higher versions of these compilers.

First, create the overall CRETE directory:
```bash
mkdir crete
cd crete
```

Grab a copy of the source tree:
```bash
git clone --recursive https://github.com/SVL-PSU/crete-dev.git crete-dev
```

From outside of the ```crete-dev``` directory in the overall CRETE directory:
```bash
mkdir crete-build
cd crete-build
CXX=clang++-3.4 cmake ../crete-dev
make # use -j to speedup
```

#### Miscellaneous Setup

As documented on the STP and KLEE website, it is essential to set up the limit
on open files and stack size. In most cases, the hard limit will have to be
increased first, so it is best to directly edit the /etc/security/limits.conf
file. For example, add the following lines to limits.config.
```bash
* soft stack unlimited
* hard stack unlimited
* soft nofile 65000
* hard nofile 65000
```

You can also add the executables and libraries to your .bashrc file:
```bash
echo '# Added by CRETE' >> ~/.bashrc
echo export PATH='$PATH':`readlink -f ./bin` >> ~/.bashrc
echo export LD_LIBRARY_PATH='$LD_LIBRARY_PATH':`readlink -f ./bin` >> ~/.bashrc
echo export LD_LIBRARY_PATH='$LD_LIBRARY_PATH':`readlink -f ./bin/boost` >> ~/.bashrc
source ~/.bashrc
```

At this point, you're all set with building CRETE!

## 3. Preparing the Guest Operating System
>#### Note
> You may skip this section by using a prepared VM image
  [crete-demo.img](http://svl13.cs.pdx.edu/crete-demo.img). This image has
  Ubuntu-14.04.5-server-amd64 installed as the Guest OS along with all CRETE
  guest utilities.
>
> Root username: __test__
>
> Password: __crete__

The front-end of CRETE is an instrumented VM (crete-qemu). You need
to setup a QEMU-compatible VM image to perform a certain test upon
CRETE. To get the best performance, native QEMU with kvm enabled should be used for
all setups on the guest VM image. 

Native qemu can be attained by compiling the source code provided on on the qemu website. In this user manual, native qemu commands will be signified with _native-qemu_ in place of _qemu_ to distinguish them from default qemu commands.

### 3.1. Create a QEMU Image

```bash
$ qemu-img create -f qcow2 <img-name>.img <img-size>G
```

Where &lt;img-name&gt; is the desired name of your image, and &lt;img-size&gt;
is the upper bound of how large the image can grow to in Gigabytes. See [this
page](http://en.wikibooks.org/wiki/QEMU/Images#Creating_an_image) for more
details.

### 3.2. Install the Guest OS

```bash
$ native-qemu-system-x86_64 -hda <img-name>.img -m <memory> -k en-us -enable-kvm -cdrom <iso-name>.iso -boot d
```
Where &lt;memory&gt; is the amount of RAM in Megabytes, &lt;img-name&gt; is the
name of the image just created, and &lt;iso-name&gt; is the name of the .iso used to install Ubuntu. The iso of ubuntu-12.04.5-server-amd64, for
example, can be downloaded [here](http://releases.ubuntu.com/12.04/ubuntu-12.04.5-server-amd64.iso). From this
point, follow the installation procedure to install the OS to the image.

See [this page](http://wiki.qemu.org/download/qemu-doc.html#sec_005finvocation) for
more boot options.

### 3.3. Boot the OS

Once the OS is installed to the image, it can be booted with:

```bash
$ native-qemu-system-x86_64 -hda <img-name>.img -m <memory> -k en-us -enable-kvm

```

Where &lt;memory&gt; is the amount of RAM (Megabytes), &lt;img-name&gt; is the name of the image.

>#### Note
>
>If booting Ubuntu 12.04 hangs, first boot to recovery mode, then resume to
 normal boot. This is likely caused by driver display problems in Ubuntu.

### 3.4. Build CRETE Guest Utilities
Install the following dependencies on the guest OS:
```bash
$ sudo apt-get update
$ sudo apt-get install build-essential cmake libelf-dev libcap2-bin -y
```

Compile CRETE utilties on the guest OS. Ensure that the symbolic links within the _lib_ folder are retained during the copying process by using "scp -r" or "cp -Lr".

```bash
$ scp -r <host-user-name>@10.0.2.2:</path/to/crete/front-end/guest> .
$ mkdir guest-build
$ cd guest-build
$ cmake ../guest
$ make
```
### 3.5. Other Guest OS Configurations
Address Space Layout Randomization (ASLR) must be disabled on account of the
need for program addresses to remain consistent across executions/iterations. To
disable ASLR (Ubuntu 12.04):

```bash
echo "" | sudo tee --append /etc/sysctl.conf
echo '# Added by CRETE' | sudo tee --append /etc/sysctl.conf
echo '# Disabling ASLR:' | sudo tee --append /etc/sysctl.conf
echo 'kernel.randomize_va_space = 0' | sudo tee --append /etc/sysctl.conf
```

Set the following enviroment variables for using CRETE guest utilities (the
following script works on ubuntu 12.04 and assumes the "guest-build" locates
at the home folder):
```bash
echo ""  >> ~/.bashrc
echo '# Added by CRETE' >> ~/.bashrc
echo 'export PATH=$PATH:~/guest-build/bin' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/guest-build/bin'  >> ~/.bashrc
echo 'export C_INCLUDE_PATH=$C_INCLUDE_PATH:~/guest/lib/include'  >> ~/.bashrc
echo 'export LIBRARY_PATH=$LIBRARY_PATH:~/guest-build/bin'  >> ~/.bashrc
echo 'export LD_BIND_NOW=1'  | sudo tee --append /etc/sysctl.conf
```

### 3.6. Initiating CRETE and Saving a Snapshot
On your guest OS, run 'crete-run' without any arguments:

```bash
$ crete-run
```

You should see:
```xml 
[CRETE] Waiting for port...
```

This indicates you have run _crete-run_ successfully and can proceed.
.
Save the snapshot under 'test' again.

```bash
ctrl+alt+2
$ savevm test
enter
$ q
enter
```

Now, the guest OS is all set for using CRETE.

>### Tips for Using QEMU
>When QEMU is running, it provides a monitor console for interacting with
QEMU. The monitor can be accessed from within QEMU by using the hotkey
combinations _ctrl+alt+2_, while _ctrl+alt+1_ allows you to switch back to the
Guest OS. One of the most useful functionalities of the monitor is saving and
loading snapshots.
>
>#### Save Snapshot
>Switch to monitor by pressing _ctrl+alt+2_ and use command:
>```bash
>$ savevm <snapshot-name>
>```
>Where &lt;snapshot-name&gt; is the name you want to identify the snapshot by.
>
>#### Load Snapshot
>To load a snapshot while launching QEMU from the host OS:
>```bash
>$  native-qemu-system-x86_64 -hda <img-name>.img -m <memory> -k en-us -loadvm <snapshot-name>
>```
>Note that the boot command of QEMU that loads a snapshot has to stay consistent with
the boot command of QEMU while saving snapshot, such as using the same <memory>
on the same image. Also note that saving and loading snapshots cannot be done between
non-kvm and kvm modes.
>
>#### File Transfer Between the Guest and Host OS
>
>The simplest way to transfer files to and from the guest OS is with the _scp_ command.
>
>The host OS has a special address in the guest OS: **10.0.2.2**
>
>Here's an example that copies a file from the host to the guest:
>```bash
>scp <host-user-name>@10.0.2.2:<path-to-source-file> <path-to-destination-file>
>```
>#### Gracefully Closing the VM
>When working with snapshots, it's often easiest to save a snapshot and close
 the VM from the monitor console rather than resorting to killing it or shutting
 it down. To gracefully close the VM:
>```
>ctrl+alt+2
>q
><enter>
>```
>Where &lt;enter&gt; means depress the _Enter_ key on your keyboard.
>
>#### Warning
>Try to avoid running more than one VM instance on a given image at a time, as
it may cause image corruption.

## 4. Generating Test Cases for Linux Binaries
This section will show how to use CRETE to generate test cases for unmodified Linux
binaries. This manual will use "crete.img" as the VM image
prepared for CRETE. to utilize __echo__ from _GNU CoreUtils_ as the target
binary under test.

### 4.1 Setting Up the Test on the Guest OS
#### Provide a Configuration File for the Target Binary
First, boot the VM image using QEMU without kvm-enabled:
```bash
$ qemu-system-x86_64 -hda crete.img -m 256 -k en-us
```
A sample configuration file, _crete.demo.echo.xml_, for _echo_ is given as follows :
```xml
<crete>
	<exec>/bin/echo</exec>
	<args>
		<arg index="1" size="8" value="abc" concolic="true"/>
	</args>
</crete>
```
A brief explaination for each pertinent node is as follows (See _5. CRETE
Configuration Options_ for more information):
```xml
<exec>/bin/echo</exec>
```
This is the path to the executable under testing.
```xml
<arg index="1" size="8" value="abc" concolic="true"/>
```
In this way, we will test the binary with one concolic argument
with size of 8 bytes and its initial value is "abc".

#### Start CRETE Guest Utility on the Given Setup
With the configuration file, we are ready to use _crete-qemu_ to start the test
on the target binary.

We can take advantage of the snapshot functionality of QEMU to boost the process of
booting the guest OS by using _crete-qemu_. First, save a snapshot and quit
from QEMU:
```bash
ctrl+alt+2
$ savevm test
enter
$ q
enter
```

From the host OS, launch _crete-qemu_ by loading the snapshot we just saved:
```bash
$ crete-qemu-2.3-system-x86_64 -hda crete.img -m 256 -k en-us -loadvm test
```


Currently, CRETE can be run in two modes:
- Developer
- Distributed

Developer mode allows us to run CRETE on __one__ specific program.

Distributed mode allows us run CRETE on __multiple__ programs. 

While running CRETE in distributed mode, the image will be booted up by the _vm-node_. When you run ```crete-vm-node -c crete.vm-node.xml```, the _vm-node_ will boot the image. 

While running CRETE in Developer mode, QEMU will exit after running CRETE. On the other hand, Distributed mode will restart QEMU every time it is finished running tests. 

To run CRETE in __Distributed__ mode, follow the steps in section __4.2__ below. If you want to run __Developer__ mode, skip to section __4.3__.

### 4.2 Running CRETE in Distributed Mode


>#### General flow of setup for Distributed mode
>1. Make sure the image you created is found under vm-node/vm/1/ (vm-node/vm/1/crete.img)
>2. Boot the VM image using QEMU without kvm-enabled and sample configuration file to be tested. (crete.demo.echo.xml)
>3. Save the snapshot of the VM image as 'test'
>4. Using crete-qemu, boot the image with the snapshot. *Do not add option '-enable-kvm'. This will disable crete functionality because crete does not support KVM*
>5. Run crete-run and take a snapshot as the image begins waiting for a port 
```[CRETE] Waiting for port... ```
>6. Save the snapshot fo the VM image as 'test'
>7. Now you are ready to run ```crete-dispatch -c crete.dispatch.xml```, ```crete-vm-node -c crete.vm-node.xml``` (Run this command within vm-node folder), and ```crete-svm-node -c crete.svm-node.xml``` in seperate terminal windows

#### Image Location
Make sure the image you created is under the correct directory. The path should look like this:
```xml 
crete/crete-dev/image_template/vm-node/vm/1/crete.img 
```

#### Ensuring QEMU is Stopped

Before starting CRETE, ensure that QEMU is not currently running. To check, open a different terminal window and run the following:

```bash
telnet localhost 1234
$ q
enter
```

If the telnet command fails, QEMU is not running in the first place. Otherwise, there should now be no QEMU processes running.

#### Running crete-dispatch

In a separate terminal window in the container, locate crete.dispatch.xml. It should be found under:
```xml 
/home/crete/image_template/crete.dispatch.xml
```

Make sure the path node in crete.dispatch.xml:
```xml 
<path>/home/crete/crete-dev/image_template/vm_node/vm/1/crete.img</path>
```
matches the path to your crete.img

Run 
```bash
crete-dispatch -c crete.dispatch.xml 
```

You should see:
```xml 
[CRETE] Awaiting connection on 'symdrive-svl.cs.pdx.edu' on port '10012' ...
```
This indicates you ran _crete-dispatch_ successfully and can now run _crete-vm-node_.

#### Running crete-vm-node
In a separate terminal window in the container, locate crete.vm-node.xml. It should be found under:
```xml 
/home/crete/crete-dev/image_template/vm-node/crete.vm-node.xml 
```

Run 
```bash
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

#### Running crete-svm-node
In a separate terminal window in the container, locate crete.svm-node.xml. It should be found under:
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
crete-svm-node -c crete.svm-node.xml 
```

You should see:
```xml 
[CRETE] Connecting to master 'localhost' on port '10012' ...
entering: KleeFSM_
entering: Start
...
```

__You've successfully run CRETE in Distributed Mode!__


### 4.3 Executing CRETE Front-end on Guest OS and Back-end on the Host OS (Developer Mode)

On the guest OS, execute CRETE guest utility with the guest configuration file:
```bash
$ crete-run -c crete.demo.echo.xml
```
Now, the guest OS is all set and should be waiting for CRETE back-end on the
host OS to start.

CRETE back-end has three parts to be run on the host OS: _crete-vm-node_ for managing VM instances,
_crete-svm-node_ for managing symbolic VM instances, and _crete-dispatch_ for
coordinating the whole process.

#### Running crete-dispatch
A sample configuration file, _crete.dispatch.xml_, for _crete-dispatch_ is:
```xml
<crete>
    <mode>developer</mode>
    <vm>
        <arch>x64</arch>
    </vm>
    <svm>
        <args>
            <symbolic>
                --max-memory=1000
                --disable-inlining
                --use-forked-solver
                --max-sym-array-size=4096
                --max-instruction-time=5
                --max-time=150
                --randomize-fork=false
                --search=dfs
            </symbolic>
        </args>
    </svm>
    <test>
        <interval>
            <trace>10000</trace>
            <tc>10000</tc>
            <time>900</time>
        </interval>
    </test>
    <profile>
        <interval>10</interval>
    </profile>
</crete>
```
Start _crete-dispatch_ with the sample configuration file:
```bash
$ crete-dispatch -c crete.dispatch.xml
```
*More information about the markup can be found in section 5

#### Running crete-vm-node
A sample configuration file, _crete.vm-node.xml_, for _crete-vm-node_ is:
```xml
<crete>
    <vm>
        <count>1</count>
    </vm>
    <master>
        <ip>localhost</ip>
        <port>10012</port>
    </master>
</crete>
```
Start _crete-vm-node_ with the sample configuration file (_crete_vm_node_ must
be started from the same folder where the _crete-qemu_ was started):
```bash
$ crete-vm-node -c crete.vm-node.xml
```
#### Running crete-svm-node
A sample configuration file, _crete.svm-node.xml_, for _crete-svm-node_ is:
```xml
<crete>
    <svm>
        <path>
               <symbolic>/path-to-crete-build/bin/crete-klee-1.4.0</symbolic>
        </path>
        <count>1</count>
    </svm>
    <master>
        <ip>localhost</ip>
        <port>10012</port>
    </master>
</crete>
```
Start _crete-svm-node_ with the sample configuration file:
```bash
$ crete-svm-node -c crete.svm-node.xml
```

### 4.4 Collecting Results on the Host OS
TBA

## 5. Configuration Options

### Main Configuration

Configuration is done within the guest OS via an XML file that is passed as an argument to _crete-run_.

Example:
```bash
crete-run -c crete.xml
```

The configuration file (crete.xml) may be arbitrarily named, but the contents must match the following structure (order does not matter).

```xml
<crete>
    <exec>string</exec>
    <args>
        <arg index="<uint>" size="<uint>" value="<string>" concolic="<bool>"/>
    </args>
    <files>
        <file path="<string>" size="<uint>" concolic="<bool>"/>
    </files>
    <stdin size="<uint>" value="<string>" concolic="<bool>"/>
</crete>
```

Item-by-item:

#### crete.exec
```xml
<exec>string</exec>
```
- Type: string.
- Description: the full path to the executable to be tested.
- Optional: no.

#### crete.args
```xml
<args></args>
```
Command line arguments to the executable are defined here.

There is a single default argument for _index="0"_, as defined by the system (typically a path to the executable). By listing an _arg_ element for _index="0"_, you will overwrite this default argument.

#### crete.args.arg
```xml
<args>
    <arg index="<uint>" size="<uint>" value="<string>" concolic="<bool>"/>
</args>
```
index:
- Type: unsigned int.
- Description: index of argv[] that this element will apply to.
- Optional: no.

size:
- Type: unsigned int.
- Description: number of bytes of the argument __not__ including the null terminator.
- Optional: yes, if _value_ is given (from which _size_ can be derived).

value:
- Type: string.
- Description: the initial value of the argument (if concolic), or the constant
value of the argument (if not concolic).
- Optional: yes, if _size_ is given.

concolic:
- Type: boolean
- Description: designate this argument to have test values generated for it.
- Optional: yes - defaults to _false_.

### crete-dispatch Configuration

#### Running Developer Mode

```xml
<crete>
    <mode>developer</mode>
    <vm>
        <arch>x64</arch>
    </vm>
    <svm>
        <args>
            <symbolic>
                --max-memory=1000
                --disable-inlining
                --use-forked-solver
                --max-sym-array-size=4096
                --max-instruction-time=5
                --max-time=150
                --randomize-fork=false
                --search=dfs
            </symbolic>
        </args>
    </svm>
    <test>
        <interval>
            <trace>10000</trace>
            <tc>10000</tc>
            <time>900</time>
        </interval>
    </test>
    <profile>
        <interval>10</interval>
    </profile>
</crete>
```

A brief explaination of each pertinent node is as follows:

Set the mode to developer

```xml
<mode>developer</mode>
```

Describes the architecture of the guest OS's machine

```xml
<vm>
        <arch>x64</arch>
</vm>
```

Desribes the symbolic arguments the user want to use.

```xml
<svm>
	<args>
		<symbolic>
		...
		...
		...
		</symbolic>
	</args>
</svm>
```

This section describes how many tests to run and how long to wait to terminate main task

- trace: number of tests to run before stopping
- time: Time to wait before stopping automatically (in seconds).

```xml
<test>
        <interval>
            <trace>10000</trace>
            <tc>10000</tc>
            <time>900</time>
        </interval>
</test>
```

#### Running Distributed Mode

There will be some minor differences in the markup

```xml
<crete>
    <mode>distributed</mode>
    <vm>
      <image>
        <path>/home/crete/image_template/vm-node/vm/1/crete.img</path>
        <update>false</update>
      </image>
      <arch>x64</arch>
      <snapshot>test</snapshot>
      <args>-m 256</args>
    </vm>
    <svm>
        <args>
            <symbolic>
                --max-memory=1000
                --disable-inlining
                --use-forked-solver
                --max-sym-array-size=4096
                --max-instruction-time=5
                --max-time=150
                --search=dfs
            </symbolic>
        </args>
    </svm>
    <test>
        <interval>
            <trace>10000</trace>
            <tc>10000</tc>
            <time>900</time>
            <items>
              <item>/home/crete/crete.demo.echo.xml</item>
            </items>
        </interval>
    </test>
    <profile>
        <interval>10</interval>
    </profile>
</crete>
```

We need to specify the path to our image. Our image will be specifically found in 

```xml

<image>
        <path>/home/crete/image_template/vm-node/vm/1/crete.img</path>
        <update>false</update>
</image>
```

Then, we need to enter the name of the snapshot we saved earlier:

```xml
<snapshot>test</snapshot>
```

We removed the option to randomize the fork under symbolic arguments
We removed: --randomize-fork=false

We now include the programs (items) we want to run tests on

```xml
<items>
              <item>/home/crete/crete.demo.echo.xml</item>
</items>
```

If we were to run multiple tests then we would have multiple items under the items tag
```xml
<items>
	<item>/home/crete/crete.demo.echo.xml</item>
	<item>/path-to-item2/</item>
	<item>/path-to-item3/</item>
</items>
```

### crete-vm-node Configuration

```xml
<crete>
    <vm>
        <count>1</count>
    </vm>
    <master>
        <ip>localhost</ip>
        <port>number</port>
    </master>
</crete>
```

Set the IP address of the master as localhost

```xml
    <master>
	<ip>localhost</ip>
```

Designate the port on which the vm will communicate

```xml
	<port>number</port>
    </master>
```

### crete-svm-node configuration

```xml
<crete>
    <svm>
        <path>
            <symbolic>/path/to/klee</symbolic>
        </path>
        <count>1</count>
    </svm>
    <master>
        <ip>localhost</ip>
        <port>number</port>
    </master>
</crete>
```

Describes the path to KLEE for the svm to use

```xml
        <path>
            <symbolic>/path/to/klee</symbolic>
        </path>
```

Set the IP address of the master as localhost

```xml
    <master>
	<ip>localhost</ip>
```

Designate the port on which the vm will communicate

```xml
	<port>number</port>
    </master>
```

## 6. FAQ

### 6.1. Why is the VM not starting or misbehaving?

The most likely cause of this is the VM Image is corrupted.

There is no way to undo the damage. Forfeit the image, make a new one, and
backup regularly. Try to not run more than one VM instance on a given image at a
time.

### 6.2. Why I can't switch to QEMU monitor by using ctrl+alt+2?
A solution for this is forwarding the monitor to a local port through
telnet while launching QEMU on the host OS:
```bash
$ crete-qemu-2.3-system-x86_64 -hda crete-demo.img -m 256 -k en-us -loadvm test -monitor telnet:127.0.0.1:1234,server,nowait
```
Use the following command to access QEMU's monitor on the host OS:
```bash
$ telnet 127.0.0.1 1234
```

### 6.3. Why is "apt-get install build-essential" not working from the guest OS?
To resolve this, use the following command from the guest OS:
```bash
$ sudo rm -rf /var/lib/apt/lists/*
```
