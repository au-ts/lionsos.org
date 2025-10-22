+++
title = 'Running on QEMU inside Docker'
draft = false
weight = 100
+++

# Running on QEMU inside Docker

Although the firewall can be run on QEMU natively, to test it effectively it
requires a more complicated networking backend than is typically required when
using QEMU. The default QEMU network backend
[SLIRP](https://wiki.qemu.org/Documentation/Networking) implements a virtual
NAT'd network with very little configurability. The better, more versatile
option is to use a TAP network backend which supplies QEMU with a virtual NIC,
and allows the host to configure the desired network topology. The problem with
this is that configuring this network topology is very dependent on the
operating system of the host, and in the case of macOS creating a TAP network
interface is no longer supported, or at least not without the use of kernel
extensions.

To standardise the TAP network backend for the firewall running on QEMU, we have
created a ubuntu Docker container along with scripts to be run inside the
container to initialise the networking and test the various firewall
functionalities. The Dockerfile for the container can be found inside the
[LionsOS repository](https://github.com/au-ts/lionsos), in
`examples/firewall/docker`. All the scripts referred on this page can be found
within the scripts directory `examples/firewall/docker/scripts`. Most of these
scripts rely on configuration variables set in `firewall_configuration.sh`, so
be sure to [set them](#setting-parameters) before running the dependent
commands.

## Building and running the Docker container

The following instructions describe how to build and run the Docker container.
We still recommend building the firewall QEMU image on your host machine, and
sharing the image with the Docker container. For instructions on building the
firewall, see the section on [building](../building).

The following building and running commands can also be found in the script
`building_running.sh`.

### Setting parameters

Before building the Docker image, ensure you set the required environment
variables in `firewall_configuration.sh`. Most of these variables have a default
value that can remain unchanged, but you will need to set the following:

```sh
# Path to LionsOS repo, used for sharing the image and scripts with the container
export LIONSOS_REPO=

# Host ssh public key, used by the container to authenticate incoming ssh connections
export HOST_SSH_PUB_KEY=

# Path to host identity, used for connecting to the container
export HOST_KEY_PATH=
```

We use an SSH connection to the container to allow the firewall's configuration
webserver to be accessible from your host's browser. If you do not wish to use
this functionality these values can be ignored. If you are happy to use your
default SSH identity key to connect to the container, you can also ignore the
`HOST_KEY_PATH` variable and remove the `-i` identity file specifier from your
[SSH commands](#connecting-to-the-docker-container).

#### Network configuration variables

The IP address and subnet of each firewall interface can also be changed by
modifying this file. However, the values set in this file are only used for
creating the virtual network in the Docker container, and will not update the
build-time values set in the firewall metaprogram which are used to create the
firewall image. The default network configuration values are set to match the
default IP addresses and subnets in the metaprogram, so if you wish to change
them you will need to ensure you also change the corresponding [metaprogram
values](../building#firewall-system-constants) and rebuild the image.

### Building

To build the Docker image, run the following command within the `docker`
directory:

```sh
docker build -f Dockerfile . -t ${DOCKER_IMAGE}
```

This will create a ubuntu Docker image with all the necessary networking, SSH
and QEMU packages.

### Running

To run the container, run the following following command:

```sh
docker run -it \
    --privileged --cap-add=NET_ADMIN --cap-add=NET_RAW \
    -v ${LIONSOS_REPO}:/mnt/lionsOS \
    -p ${HOST_SSH_PORT}:22 \
    --name ${DOCKER_CONTAINER} \
    ${DOCKER_IMAGE}
```

The options used in the command are:
- `-it` starts an interactive shell
- `--privileged --cap-add=NET_ADMIN --cap-add=NET_RAW` grants the container
  additional privelages required to configure the network
- `-v ${LIONSOS_REPO}:/mnt/lionsOS` mounts the host LionsOS repository to the
  container's `mnt` directory, which we use to access the firewall image and
  relevant scripts
- `-p ${HOST_SSH_PORT}:22` enables host to guest port forwarding, which we will
  use to SSH into the container. As mentioned in the [setting
  parameters](#setting-parameters) section, this is only required for accessing
  the firewall webserver from your host browser thus may be omitted if you do
  not wish to access the GUI in this way

If this is successful the container should now be running with an interactive
shell. To confirm the file mounting was successful, you can run:

```sh
root@1c3cc4f86117:~# echo $DOCKER_CONTAINER
firewall_container
```

## Internal container set up

Some of the container setup needs to be run from within the container, namely
setting up the virtual network and (optionally) starting the ssh daemon.

### Virtual network creation

To create the TAPs, bridges, veths and namespaces required, run the
`net_setup.sh` script:

```sh
root@1c3cc4f86117:/# mnt/lionsOS/examples/firewall/docker/scripts/net_setup.sh 
net.bridge.bridge-nf-call-iptables = 0
```

Note that the output from this script is the result of the command

```sh
sysctl -w net.bridge.bridge-nf-call-iptables=0
```
which disables the kernel sending bridge traffic to iptables. The `net_setup.sh`
script also disables bridge filtering which can drop firewall traffic by
default.

The `net_setup.sh` script creates the virtual network pictured in the following
diagram (although the firewall itself is not running yet):

<img style="display: block; margin-left: auto; margin-right: auto"
src="/firewall_tap_network.svg" alt="Docker virtual network" width="800" />

### Enabling SSH

To enable the SSH daemon and add your public key to the set of authorised keys,
run the following script:

```sh
root@1c3cc4f86117:/# mnt/lionsOS/examples/firewall/docker/scripts/ssh_setup.sh 
 * Starting OpenBSD Secure Shell server sshd                 [ OK ] 
 * sshd is running
```

You should now be able to SSH into the container.

### Connecting to the Docker container

To open an interactive terminal into the container run:

```sh
docker exec -it ${DOCKER_CONTAINER} /bin/bash
```

To SSH into the container run:

```sh
ssh -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -i ${HOST_KEY_PATH} \
    root@localhost -p ${HOST_SSH_PORT}
```

We disable adding the container to your known hosts as this may potentially
cause conflicts if the container is rebuilt.

## Running the firewall

Before running the firewall, ensure the firewall
[metaprogram](../building#firewall-system-constants) configuration matches your
Docker network, and a [firewall QEMU image](../building) has been created within
your LionsOS repository. You can then run the `qemu.sh` script which instructs
QEMU to run your firewall image with the TAP network backend we just configured:

```sh
root@1c3cc4f86117:/# mnt/lionsOS/examples/firewall/docker/scripts/qemu.sh
```

By default the script assumes that the firewall image is located at
`/mnt/lionsOS/examples/firewall/build/firewall.img`, however an alternative
location can be passed as the first argument. If this is successful, the
firewall should immediately boot and behave in the same way as described in the
section on [booting](../running#booting), although it will not receive any
traffic until you generate it. Instructions on this can be found in the
[testing](../testing) section.
 
## Accessing the firewall webserver from your browser

Once the firewall is running, if you have configured your container to support
SSH connections, you should now be able to access the firewall webserver page
from your host machine's web browser. To enable this, you must first open an SSH
connection with port forwarding:

```sh
ssh -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -L ${HOST_HTTP_PORT}:${FW_INT_IP}:80 \
    -i ${HOST_KEY_PATH} \
    root@localhost -p ${HOST_SSH_PORT}
```

This is the same command described [above](#connecting-to-the-docker-container),
with the addition of the port forwarding option which funnels traffic from your
host machine to the container, which then forwards the traffic to the internal
IP of the firewall and back. The flow of traffic is displayed in the diagram
below:

<img style="display: block; margin-left: auto; margin-right: auto"
src="/firewall_ssh_forwarding.svg" alt="Host to container firewall GUI traffic flow" width="800" />

With this port forwarding SSH connection open you should now be able to see the
firewall configuration home page in your host browser at
`localhost:{HOST_HTTP_PORT}`.

<img style="display: block; margin-left: auto; margin-right: auto"
src="/firewall_webgui_home.png" alt="Webserver GUI home page" width="500" />
