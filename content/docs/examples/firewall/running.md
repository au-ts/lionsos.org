+++
title = 'Running on hardware'
draft = false
weight = 100
+++

# Running on hardware

To effectively test the firewall system when running on real hardware, each
network interface must be connected to a distinct subnet with the firewall being
the only means to achieve communication between the subnets. Hosts on each
subnet must then be configured to forward non-local traffic to the firewall.

Unlike most LionsOS systems which use software defined MAC addresses, the
firewall uses the MAC address of each NIC (although the [software still requires
knowledge of this](https://github.com/au-ts/lionsos/issues/185)).

The firewall also requires a statically defined IP address, as well as its local
subnet at build time to construct its local routing table routes.

Since the firewall [does not currently support
NAT](https://github.com/au-ts/lionsos/issues/188), the typical way traffic is
routed through the firewall is to set up IP forwarding for traffic destined for
the opposing subnet to be routed to the firewall's local IP. This requires at
least one host on both subnets with these IP forwarding rules.

## Booting

When first booting up the system if everything works correctly, you should see
serial output dependent on whether or not you have configured the system for
[additional debug output](../building). Regardless of whether debug output is
turned on, the Micropython webserver component should output a status message
indicating that the webserver is starting:

```sh
Starting async server on 0.0.0.0:80...
```

Once the system has booted, the webserver GUI should be accessible from the
internal network by visiting the firewall's "internal" IP address at port 80.

If debug output is turned on there will be some degree of serial interference
due to the high number of components printing simultaneously, however once
system initialisation is complete it should be possible to track each packet's
progression through the firewall. For example, a typical log of print statements
when the webserver is accessed looks as follows:

```sh
MON|INFO: Microkit Monitor started!
MON|INFO: PD 'timer_driver' is now passive!
'routing' is client 0
'micropython' is client 1
'icmp_module' is client 2
'arp_responder0' is client 3
'arp_requester0' is client 4
'arp_responder1' is client 5
'arp_requester1' is client 6
'arp_responder2' is client 7
'arp_requester2' is client 8
ROUTING|LOG: routing table initialized with 3 entries:
ROUTING|LOG:   route 0: ip=172.16.0.0 subnet=16 interface=0 next_hop=0.0.0.0
ROUTING|LOG:   route 1: ip=192.168.1.0 subnet=24 interface=1 next_hop=0.0.0.0
ROUTING|LOG:   route 2: ip=10.0.2.0 subnet=24 interface=2 next_hop=0.0.0.0
MP|INFO: initialising!
Starting async server on 0.0.0.0:80...
ARP RESPONDER|LOG: replying for ip 172.16.2.1 on interface 0
ICMP FILTER|LOG: on interface 0 transmitting via rule 0: (ip 172.16.2.200, port 0) -> (ip 192.168.1.100, port 0)
ROUTING|LOG: received packet on interface 0 for ip 192.168.1.100 with buffer number 4
ROUTING|LOG: converted ip 192.168.1.100 to next hop ip 192.168.1.100 arrived on interface 0, exiting on out interface 1
ARP REQUESTER|LOG: processing client 0 request for ip 192.168.1.100 on interface 1
ARP REQUESTER|LOG: received response for client 0, ip 192.168.1.100. MAC[0] = b6, MAC[5] = 6e on interface 1
ROUTING|LOG: dequeuing response for ip 192.168.1.100 on interface 1 and MAC[0]= b6, MAC[5] = 6e
ROUTING|LOG: sending packet received on interface 0 out of interface 1 for ip 192.168.1.100 with buffer number 4
ICMP FILTER|LOG: on interface 1 transmitting via rule 0: (ip 192.168.1.100, port 0) -> (ip 172.16.2.200, port 0)
ROUTING|LOG: received packet on interface 1 for ip 172.16.2.200 with buffer number 3
ROUTING|LOG: converted ip 172.16.2.200 to next hop ip 172.16.2.200 arrived on interface 1, exiting on out interface 0
ARP REQUESTER|LOG: processing client 0 request for ip 172.16.2.200 on interface 0
```
