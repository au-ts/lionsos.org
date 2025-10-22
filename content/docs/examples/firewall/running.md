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
INT --> EXT | TCP filter found no match, performing default action Allow: (ip 192.168.1.2, port 39202) -> (ip 192.168.1.1, port 80)
INT --> EXT | TCP filter transmitting via rule 0: (ip 192.168.1.2, port 39202) -> (ip 192.168.1.1, port 80)
INT --> EXT | Router received packet for ip 192.168.1.1 with buffer number 16
INT --> EXT | Router converted ip 192.168.1.1 to next hop ip 0.0.0.0 out interface 2
INT --> EXT | Router transmitted packet to webserver
```
