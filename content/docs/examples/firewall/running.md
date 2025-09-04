+++
title = 'Running'
draft = false
weight = 100
+++

## Running on hardware

Unfortunately, since the firewall [does not currently run on
qemu](https://github.com/au-ts/lionsos/issues/195), it requires a more
complicated network set up to run and test.

Unlike most LionsOS systems which use software defined MAC addresses, the
firewall uses the MAC address of each NIC (although the [software still requires
knowledge of this](https://github.com/au-ts/lionsos/issues/185)). The firewall
also requires static IP addresses for each interface.

Each endpoint of the firewall requires knowledge of its local subnet (IP
address, subnet mask) to construct its local routing table routes. Since the
firewall [does not currently support
NAT](https://github.com/au-ts/lionsos/issues/188), the typical way traffic is
routed through the firewall is to set up IP forwarding for traffic destined for
the opposing subnet to be routed to the firewall's local IP. This requires at
least one host on both subnets with IP forwarding knowledge.
