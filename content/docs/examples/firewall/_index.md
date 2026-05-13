---
weight: 30
bookCollapseSection: true
title: "Firewall"
---

# Firewall system

The LionsOS project contains an example system that acts as a firewall between
networks. Each network interface of the firewall system has its own instance of
an sDDF net subsystem. The firewall multiplexes incoming traffic based on its
protocol, and permits or denies the traffic based on a set of build and run-time
configurable rules. The firewall also acts as a router and can forward traffic
to its next-hop based on a build and run-time configurable routing table. There
are further networking functionalities the firewall is capable of detailed
below. The firewall example is currently fairly rudimentary, and we [invite the
community](./contributing) to help complete it. A list of issues and missing
features of the firewall can be found
[here](https://github.com/au-ts/lionsos/issues?q=state%3Aopen%20label%3A%22firewall%22).


This page describes the system's architecture and details how it works, if you
are interested in building, running or testing it see the pages on:
* [Building](./building)
* [Running on hardware](./running)
* [Running on QEMU inside Docker](./docker)
* [Testing](./testing)

## Supported platforms

The system currently works on the following platforms, although we hope to
[expand this in the future](https://github.com/au-ts/lionsos/issues/195):
* QEMU virt AArch64
* Compulab IOT-GATE-IMX8PLUS

The simplest way to get started with testing and developing the firewall is to
run it on QEMU inside our custom ubuntu Docker container, which emulates the
required network infrastructure. Instructions on setting up the container can be
found in the section on [running on QEMU inside Docker](./docker).

If you are are using real hardware to test the firewall system, you will need to
configure subnets and hosts for each network interface. More details on this can
be found in the section on [running on hardware](./running).

## Architecture

Below is a diagram of the architecture of the firewall system with two network
interfaces. Components attached with arrows are connected via a Microkit Channel
and shared memory holding either an sDDF or firewall
[queue](#firewall-shared-memory-regions) data structure.

<div style="background-color: clear; display: inline-block; padding: 0.5rem">
    <img src="/firewall.svg" alt="Firewall architecture diagram" />
</div>

The firewall supports an arbitrary number of interfaces (NICs) which can be
configured in the [metaprogram](./building#firewall-metaprogram). The exact
architecture is extremely configurable. The firewall's rules and policies can be
configured further at runtime via the [webserver](#webserver) component.

## Firewall Shared Memory Regions

The firewall implements zero-copy forwarding of packets. This requires that the
data region used to receive by one interface be used for transmission by the
other interfaces. Additionally, each component that generates packets has its
own transmission data region allocated through the sDDF net sub-system.

Aside from network data regions, the majority of other shared memory regions
hold single-producer, single-consumer queues. The queue data structures that can
be found in the firewall are:

### sDDF Net Queues

An sDDF net queue is really a _pair_ of queues used to transfer data buffers
between components for transmission or reception. sDDF net queues are used in
the firewall when buffers are to be returned to the same component they are
received from. In a typical sDDF net system this is always the case, however the
firewall often requires components to return buffers to different components.
sDDF net queues also use a signalling protocol to decide when to signal their
neighbouring component. More on sDDF net queues can be found in the sDDF
networking
[docs](https://github.com/au-ts/sddf/blob/main/docs/network/network.md) and the
sDDF [design
doc](https://trustworthy.systems/projects/drivers/sddf-design-latest.pdf).

### Firewall Queues

A firewall queue is also used to transfer receive or transmit data buffers,
however only in one direction. This allows components like the transmit
virtualiser to receive buffers from the router, and return them back to the
original receive virtualiser after transmission is complete.

<img style="display: block; margin-left: auto; margin-right: auto"
src="/firewall_queues.svg" alt="Firewall queues" width="600" />

Firewall queues, along with all the following queues, do not use a signalling
protocol to determine when to signal, and instead producers signal consumers
after enqueuing a batch of data.

### ARP Queues

An ARP queue is a pair or queues (_request_ and _response_) holding ARP data,
namely IP and MAC addresses, and whether or not an IP is reachable. ARP queues
are used by [routers](#routing-components), [ARP requesters](#arp-components)
and the [webserver](#webserver) to request the MAC address of IPs they wish to
transmit to.

### ICMP Queues

ICMP queues are one-way queues between the [ICMP module](#icmp-module) and the
[filters](#filters) and [routers](#routing-components). They are used to request
transmission of ICMP packets. Routers can request the transmission of
`destination unreachable` and `timeout` packets, while filters can request the
transmission of`reject` packets. The ICMP module is also responsible for
generating ping responses for each of the firewall's interfaces, with
per-interface ping responsiveness being configurable via the
[webserver](#webserver).

### Other Shared Memory Structures

Not pictured in the diagram are the shared memory regions between components
without a Microkit Channel, namely the filters [_connection
instances_](#filters) regions shared between pairs of filters of the same
protocol.

## Firewall Components

### Firewall Network Components

The firewall network transmit (Tx) and receive (Rx) virtualisers are based on
the sDDF network virtualiser components with minimal modifications, as detailed
in the [sDDF design
document](https://trustworthy.systems/projects/drivers/sddf-design-latest.pdf). The
main modification to both virtualisers is the introduction of [firewall
queues](#firewall-queues) in addition to [sDDF net queues](#sddf-net-queues).
This alters the flow of control of the virtualisers as both queues need to be
handled differently.

#### Rx Virtualiser

The Rx virtualiser has additionally been modified to multiplex based on a
packet's Ethernet type or IPv4 protocol number, rather than the sDDF network Rx
virtualiser which uses destination MAC address. Packets are forwarded to the
corresponding [ARP](#arp-components) or [filter](#filters) component depending
on the match. The following diagram illustrates how the Rx virtualiser is
connected to its neighbours which it forwards packets to (not pictured is how
buffers are returned to the Rx virtualiser):

<img style="display: block; margin-left: auto; margin-right: auto"
src="/firewall_rx_virt.svg" alt="Firewall network virtualiser"
width="600" />

As with sDDF network Rx virtualisers, static client queue and protocol
configuration data is generated in the [metaprogram](./building) and copied into
the `.elf` file at build time.

### ARP Components

The firewall contains two distinct ARP components per NIC: the ARP responder
which simply responds to ARP requests addressed to the firewall, and the more
complex ARP requester which is responsible for handling all system ARP requests
for local IPs and maintaining ARP tables.

#### ARP Requester

The ARP requester receives ARP requests from the router, and in the case of the
ARP requester associated with the internal NIC, the webserver component.
Requests, and their eventual responses are passed between components in [ARP
queues](#arp-queues). Requests have the following structure:

```c
typedef enum {
    /* entry is not valid */
    ARP_STATE_INVALID = 0,
    /* IP is pending an arp response */
    ARP_STATE_PENDING,
    /* IP is unreachable */
    ARP_STATE_UNREACHABLE,
    /* IP is reachable, MAC address is valid */
    ARP_STATE_REACHABLE
} fw_arp_entry_state_t;

typedef struct fw_arp_request {
    /* IP address */
    uint32_t ip;
    /* MAC address for IP if response and state is valid */
    uint8_t mac_addr[ETH_HWADDR_LEN];
    /* state of arp response */
    uint8_t state;
} fw_arp_request_t;
```

It is the ARP requesters responsibility to convert this raw ARP request data
into a packet and transmit it out the network. Upon response, the requester will
insert an ARP entry into the ARP table, which the routing component also has
read-only access to. ARP entries have the following structure:

```c

typedef struct fw_arp_entry {
    /* state of this entry */
    uint8_t state;
    /* IP address */
    uint32_t ip;
    /* MAC of IP if IP is reachable */
    uint8_t mac_addr[ETH_HWADDR_LEN];
    /* bitmap of clients that initiated the request */
    uint8_t client;
    /* number of arp requests sent for this IP address */
    uint8_t num_retries;
} fw_arp_entry_t;
```

If after a configurable timeout a response has not been received, the request
will be retransmitted. If a threshold of retries is reached, the IP will be
considered unreachable and an unreachable entry will be added to the ARP table.


After a response is received or an IP is deemed unreachable, an ARP response
will be enqueued with the client who originally requested the MAC address. After
a configurable time interval the ARP table is completely flushed to ensure stale
entries are removed. Time intervals and retry limits can be configured in the
`arp_requester.c` file.

The following diagram shows how the ARP requester is connected to its clients:

<img style="display: block; margin-left: auto; margin-right: auto"
src="/firewall_arp_requester.svg" alt="ARP requester connections" width="400" />

#### ARP Responder

The ARP responder is a simple component. It requires only a statically defined
firewall IP and MAC address (obtained as configuration data generated by the
[metaprogram](./building)) to respond to ARP requests addressed to the firewall.
All ARP requests received by the NIC will be routed to the ARP responder, and
responses will only be generated if there is a match with the firewall's local
IP.

<img style="display: block; margin-left: auto; margin-right: auto"
src="/firewall_arp_responder.svg" alt="ARP responder component" width="500" />

### Filters

Filter components filter traffic - each filter is responsible for determining
whether traffic of a particular transport layer protocol should be permitted
through the firewall. They are the first component to receive IP traffic after
the network Rx virtualiser.

If a filter permits a packet through the firewall, it will transfer the packet
to the routing component via a firewall queue. If the packet is not permitted,
it will be returned back to the Rx virtualiser. For each supported IP protocol,
there is one filter per interface. Currently, the firewall contains only ICMP,
UDP and TCP filters that share a very similar implementation. We hope to [extend
our protocol specific filtering for TCP
traffic](https://github.com/au-ts/lionsos/issues/186) to support tracking of TCP
connections.

To determine whether traffic should be permitted or dropped, filter components
compare each packet to their rule tables. Rule table entries are given by the
type `fw_rule_t`. A rule is applied to a packet if the packet's source and
destination IP and port number matches against a rule (clashes are resolved by
the most specific match). If there is no match, the _default_ rule is applied.
The list of actions a filter can take upon matching with a rule is given by the
`fw_action_t` type.

```c
typedef enum {
    /* allow traffic */
    FILTER_ACT_ALLOW = 1,
    /* drop traffic */
    FILTER_ACT_DROP = 2,
    /* reject traffic (drop traffic and send back icmp unreachable) */
    FILTER_ACT_REJECT = 3,
    /* allow traffic, and additionally any return traffic */
    FILTER_ACT_CONNECT = 4,
    /* traffic is return traffic from a connect rule */
    FILTER_ACT_ESTABLISHED = 5,
} fw_action_t;

typedef struct fw_rule {
    /* action to be applied to traffic matching rule */
    uint8_t action;
    /* source IP */
    uint32_t src_ip;
    /* destination IP */
    uint32_t dst_ip;
    /* source port number */
    uint16_t src_port;
    /* destination port number */
    uint16_t dst_port;
    /* source subnet, 0 is any IP */
    uint8_t src_subnet;
    /* destination subnet, 0 is any IP */
    uint8_t dst_subnet;
    /* rule applies to any source port */
    bool src_port_any;
    /* rule applies to any destination port */
    bool dst_port_any;
    /* rule id assigned */
    uint16_t rule_id;
} fw_rule_t;
```

The `allow` and `drop` actions are self explanatory, and the `reject` action is
an extension of the `drop` action - matching traffic is dropped, *and* an ICMP
`reject` packet is sent to the original sender via the ICMP module.

The `connect` and `established` actions are related. If a packet matches with a
`connect` rule, this implies the filter should allow the packet through the
firewall, _as well as_ any return traffic. This is implemented using a pair of
shared memory regions between filters denoted _instance_ regions.

Upon matching with a `connect` rule, a filter creates a connection instance for
the packet in its instance region. Before filters check their rule tables, they
*first* check their neighbour's instance table to determine if the packet is
permitted as return traffic due to an instance created by another filter. If an
instance is found, the `established` action is applied and the traffic is
permitted. Upon the deletion of a `connect` rule, all instances corresponding to
that rule are removed.

Both the filter rule table and default rule of a filter may be updated using the
[webserver GUI](#webserver). The following diagram shows the flow of packets
through the filters, as well as the shared instances regions between matching
filters:

<img style="display: block; margin-left: auto; margin-right: auto"
src="/firewall_filter.svg" alt="Filter connections" width="700" />


### Routing Component

The routing component or router receives packets which have been allowed through
the firewall by the filter components. It is responsible for figuring out the
next-hop of each packet, the MAC address of the next-hop, updating the Ethernet
Header and transmitting the packet out the correct interface.

The first step of this procedure is to look up the destination IP in the
_routing table_ to deduce whether the destination IP (or its next-hop) belongs
to a reachable subnet, and what interface should be used to reach it. The
routing table is partially configured at build time with the
[metaprogram](./building#firewall-metaprogram) and can be re-configured at
run-time using the [webserver](#webserver) component. If multiple matches in the
routing table are found, the more precise match will be selected. If no route is
found the packet will be dropped.

If a match is found, the ARP table of the interface is searched to find the MAC
address of the next-hop. If a valid entry is not found, an ARP request is
generated and enqueued with the ARP requester, and the outgoing packet is placed
in a packets waiting (`pkts_waiting_t`) list of pending packets for the
interface.

If the ARP requester responds with a valid MAC address for the next-hop, or if
there was a pre-existing reachable entry the packet will be updated and
transmitted. If the next-hop is found to be unreachable, the packet will be
dropped. When a packet is dropped, the router sends the details of the packet to
the [ICMP module](#icmp-module) so a `destination unreachable` packet can be
transmitted back to the source IP.

The router also routes webserver traffic to the webserver component, and ICMP
ping traffic to the ICMP module depending on whether ping responsiveness is
enabled.

The following diagram demonstrates the flow of packets through the router:

<img style="display: block; margin-left: auto; margin-right: auto"
src="/firewall_router.svg" alt="Router" width="400" />

### ICMP module

The ICMP module is responsible for generating ICMP traffic on behalf of all
components in the firewall. There is only one ICMP module in the system which is
able to transmit out all interfaces.

The routing component will request an ICMP packet be transmitted upon finding
that a packet's TTL has reached zero, or a packet's destination IP address
cannot be reached. In this case, the ICMP module will send an ICMP `timeout` or
`destination unreachable` packet back to the original sender.

The ICMP module is also responsible for generating responses to pings received
on each of the firewall's interfaces. If the router receives an incoming ICMP
echo request destined for the firewall, it will forward the details to the ICMP
module depending on whether it is configured to respond. Responsiveness to pings
on a given interface is configurable at run-time via the
[webserver](#webserver).

Some filters (e.g. UDP and ICMP) support a `reject` filtering action. When
traffic matches with a reject rule, the traffic is dropped *and* the filter
requests that the ICMP module send a `destination unreachable` (port
unreachable) packet back to the original sender, informing them that the port is
unavailable.

The diagram below demonstrates the connections of the ICMP module.

<img style="display: block; margin-left: auto; margin-right: auto"
src="/firewall_icmp_module.svg" alt="ICMP module" width="500" />

### Webserver

The webserver component provides a basic web GUI for the firewall that can be
accessed via the internal network. It is reachable by the firewall's internal IP
address on port 80. Only TCP traffic is currently permitted. The GUI currently
displays:
- Network interface details (IP, MAC)
- Filtering rules for each filter and interface
- Routing table of each router

The filtering rules and routing table routes can also be added and removed.

The webserver component is the same Micropython component used in the
[webserver](../webserver) example, with slight modifications to how it receives
packets and [handles ARP requests](https://github.com/au-ts/lionsos/issues/179).
It utilises the Micropython
[Microdot](https://github.com/miguelgrinberg/microdot) library to host the
website. The front end Micropython code can be found in `ui_server.py`, and the
back end C module is implemented in `modfirewall.c`.

The following diagram shows how the webserver is connected to the system:

<div style="background-color: clear; display: inline-block; padding: 0.5rem">
    <img src="/firewall_webserver.svg" alt="Webserver component" />
</div>

In contrast to all other connections in the firewall, the webserver uses
protected procedure calls (PPCs) to modify the state of filter and routing
components. Since it is not anticipated the routes and rules will be updated at
a high frequency, this significantly simplifies the interface. The webserver has
all filter rules and routing tables mapped into its address space read-only,
which allows them to efficiently be displayed without disrupting the flow of
traffic through the system. A PPC is only required for modification.

The following images show the GUI pages for viewing and updating routing table
routes, the ICMP filter's rules, and the firewall's ping responsiveness
settings:

<img style="display: block; margin-left: auto; margin-right: auto"
src="/firewall_webgui_router.png" alt="Webserver GUI routing table page" width="500" />


<img style="display: block; margin-left: auto; margin-right: auto"
src="/firewall_webgui_icmprules.png" alt="Webserver GUI ICMP filter page" width="700" />

<img style="display: block; margin-left: auto; margin-right: auto"
src="/firewall_webgui_icmpping.png" alt="Webserver GUI ICMP ping page" width="700" />
