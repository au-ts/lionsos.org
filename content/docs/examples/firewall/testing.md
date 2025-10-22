+++
title = 'Testing'
draft = false
weight = 100
+++

# Testing the firewall

This page describes how to test all the currently implemented functionalities of
the firewall. We assume that you are using the QEMU Docker container setup,
however similar commands and tests can be used for a real hardware setup. The
commands described on this page can all be found in the `testing.sh` script in
the Docker scripts directory `examples/firewall/docker/scripts`. These commands
use environment variables set in `firewall_configuration.sh`. If you are running
the commands inside the container, these variables should already be set.

## Executing from namespaces

To force traffic to flow through the firewall, we created two isolated network
namespaces named `ext` (external) and  `int` (internal). To execute a command
from within a namespace, you prepend the command with the following prefixes:

```sh
# Execute from ext namespace
ip netns exec ext

# Execute from int namespace
ip netns exec int
```

The external namespace has only two routes - a local subnet route and a default
route which forwards all non-local traffic to the external interface of the
firewall:

```sh
root@db756615e5c4:/# ip netns exec ext ip route
default via 172.16.2.1 dev ext-br0 
172.16.0.0/12 dev ext-br0 proto kernel scope link src 172.16.2.200
```

Thus when the external namespace attempts to reach an IP belonging to the
internal network, it will forward the traffic to the external IP of the
firewall. The same setup applies for the internal namespace.

## Forwarding traffic through the firewall

Traffic can be sent through the firewall from the external network to the
internal network, and vice versa. The following commands test the ability of the
firewall to route and filter traffic between networks. This actually tests many
components of the firewall including but not limited to:
- The [ARP responder component](../#arp-responder), which must be replying
  correctly for the firewall's IP address to be matched to its MAC address
- The corresponding [filter](../#filters) component, which must be applying its
  rules correctly to allow or deny the traffic (rules can be configured using
  the firewall's GUI)
- The [routing](../#routing-components) component, which must be correctly
  identifying the route to the destination subnet
- The [ARP requester](../#arp-requester) component, which must be sending out
  ARP requests for the destination IP, and receiving and processing responses

Additionally successful traffic flow also verifies that the ethernet drivers and
network virtualisers are working correctly.

### ICMP

To forward a ping through the firewall, execute the following commands:

```sh
# ICMP: ext --> int
ip netns exec ext ping ${INT_HOST_IP}

# ICMP: int --> ext
ip netns exec int ping ${EXT_HOST_IP}
```

### TCP

To create a TCP connection between the two namespaces using `netcat`, you must
have one namespace endpoint listen on a port, and the other initiate a
connection on the same port:

```sh
# TCP: ext listens, int initiates
ip netns exec int nc -l ${TEST_PORT}
ip netns exec ext nc ${INT_HOST_IP} ${TEST_PORT}

# TCP: int listens --> ext initiates
ip netns exec ext nc -l ${TEST_PORT}
ip netns exec int nc ${EXT_HOST_IP} ${TEST_PORT}
```

Once the connection is established, input entered into one terminal should come
through as output on the other.

### UDP

UDP is essentially the same as TCP, with an additional netcat `-u` flag:

```sh
# UDP: ext listens, int initiates
ip netns exec int nc -ul ${TEST_PORT}
ip netns exec ext nc -u ${INT_HOST_IP} ${TEST_PORT}

# UDP: int listens --> ext initiates
ip netns exec ext nc -ul ${TEST_PORT}
ip netns exec int nc -u ${EXT_HOST_IP} ${TEST_PORT}
```

## ICMP destination unreachable

Currently the ICMP module is [only
capable](https://github.com/au-ts/lionsos/issues/194) of sending `destination
unreachable` packets when the destination IP address can't be resolved. To test
this, you can attempt to ping an IP address that doesn't exist:

```sh
ip netns exec ext ping ${INT_BAD_HOST_IP}
ip netns exec int ping ${EXT_BAD_HOST_IP}
```

Initially this will cause the ARP requester to send out an ARP request for the
bad IP. The requester will retry a total of 5 times (once per second), until it
eventually decides the IP is unreachable. It will then notify the router about
this, which will trigger the router to send a request to the ICMP module to send
an ICMP 'destination unreachable' packet back to the original sender. This
should result in your ping command outputting the following:

```sh
root@db756615e5c4:~# ip netns exec ext ping ${INT_BAD_HOST_IP}
PING 192.168.1.101 (192.168.1.101) 56(84) bytes of data.
From 172.16.2.1 icmp_seq=1 Destination Host Unreachable
From 172.16.2.1 icmp_seq=2 Destination Host Unreachable
From 172.16.2.1 icmp_seq=3 Destination Host Unreachable
From 172.16.2.1 icmp_seq=4 Destination Host Unreachable
From 172.16.2.1 icmp_seq=5 Destination Host Unreachable
```

## Monitoring traffic and debugging

Traffic can be monitored as it travels through the firewall through the use of
debug printing, which by default is turned on. Each compoonent of the firewall
prints as it processes a packet with details of how the packet is being
processed, as well as destination and source IP and MAC address.

In addition, you can use `tcpdump` on each virtual interface within the
container, with some interfaces only being accessible from within the internal
or external namespaces. Starting from the veth connected to the external name
space in the external -> internal direction, the following `tcpdump` commands
can be used:

```sh
# TCP dump interfaces (e - include ethernet, x - hexdump packet, -i interface)

# veth attached to the external namespace
ip netns exec ext tcpdump -ex -i ext-br0

# veth attached to the external bridge
tcpdump -ex -i br0-ext

# external bridge
tcpdump -ex -i br0

# external tap of the firewall
tcpdump -ex -i tap0

# internal tap of the firewall
tcpdump -ex -i tap1

# internal bridge
tcpdump -ex -i br1

# veth attached to the internal bridge
tcpdump -ex -i br1-int

# veth attached to the internal namespace
ip netns exec int tcpdump -eX -i int-br1
```

Using these commands allows you to trace traffic through the virtual network,
and can be particularly useful if you find your traffic getting _stuck_
somewhere.
