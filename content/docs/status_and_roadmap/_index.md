---
weight: 100
bookFlatSection: false
title: "Status & Roadmap"
---

# Status & Roadmap

We have had a couple of alpha releases of LionsOS now.

We have a number of example systems that show off the features and
capabilities of LionsOS on a number of ARM and RISC-V platforms.

We have various [I/O device classes](../components/io) and are getting
to the point where there are enough device class designs to make useful
systems. For a full list of the device classes and drivers we support,
see [sDDF](https://github.com/au-ts/sddf/blob/main/docs/drivers.md).

As we have been doing development on LionsOS itself, we are making
more and more complex systems that get closer to real-life deployable systems.

By doing so we have been able to improve the usability and off-the-shelf
functionality that LionsOS provides, but there is still much work that is
being done on LionsOS and is to be done in the future.

To send feature requests, or ask about the status of items on our roadmap,
please [contact us](../contributing#getting-help).

## Roadmap


| Feature | Current status | Timeline | Available at |
|---------|----------------|----------|--------------|
| [Better tooling for building systems](#tooling) | Implementation | Q4'26 | [microkit_acacia](https://github.com/au-ts/microkit_acacia/) |
| [Generic queues for OS communication](#generic-queues) | Planning | Q4'26 | N/A |
| [Verified drivers in Pancake](#pancake) | Implementation | Q4'26 | [pancake.md](https://github.com/au-ts/sddf/blob/main/docs/pancake.md) |
| [PCIe passthrough for libvmm](#pcie-passthrough) | Implementation | Q4'26 | TODO @billn |
| [More tutorials and guides](#tutorials) | Unstarted | Q4'26 | N/A |

Status:

* *Unstarted:* We have not started working on this.
* *Planning:* We are working on designs for how this will be implemented.
* *Implementation:* We are actively writing code.
* *Complete:* We have completed this, but it is not yet released.

Timeline:

* Q24'26: We are aiming on completing a LionsOS 0.5.0 release, including
  sDDF 0.8.0 and libvmm 0.3.0 at the end of 2026.


### Better tooling for building systems {#tooling}

LionsOS release 0.3.0 introduced a new ['meta program' tooling](
../releases/0.3.0/#metaprogram-tooling) to make it easier to construct LionsOS
systems. This was motivated by our need to maintain many different copies of the
[Microkit System Description Files](
https://docs.sel4.systems/projects/microkit/manual/latest/#sysdesc) and allow
multiple re-use of system components, e.g. the network stack and its configurations.

We've found that our initial tool, [sdfgen](https://github.com/au-ts/microkit_sdf_gen)
was quickly outgrown by our needs, and required knowledge about how the 'OS'
components of our systems were put together to be able to use effectively.

Our redesign, 'Acacia', is intended to replace the Zig tooling with Python scripts
co-located inside sDDF, LionsOS and libvmm.

### Generic queues for OS communication {#generic-queues}

Our I/O device classes ([sDDF](../components/io)) implement a variety of lockless
queues which are specific to each device class, but all of them behave similarly,
and [could be unified into one queue structure](
https://github.com/seL4/rfcs/pull/19#issuecomment-4713252927) for use across
the Operating System, and even for Client-Client asynchronous communication.

We are aiming to have a reuseable framework for writing these queues, and use
it to rebuild our existing queues, de-duplicating our work on checking the
correctness of memory barriers and the [Signalling protocol](
https://github.com/au-ts/sddf/blob/0.7.0/docs/developing.md#signalling-protocol).

### Verified drivers in Pancake {#pancake}

One of our research projects is the [Pancake Systems Language](
https://trustworthy.systems/projects/pancake) which is designed to make
verification of OS components (drivers, virtualisers) easy through a verified
compiler based on CakeML.

We have had verification of functional correctness for several Ethernet drivers,
and recently completed verification of the Transmit Virtualiser; with work to
link this up to the [Device implementation](
https://trustworthy.systems/projects/deviceformalisation).

This work is about merging our Pancake variants of our device classes into
mainline sDDF. So far, the Serial drivers have Pancake implementations and we
are working on Ethernet and other classes.

### PCIe Passthrough {#pcie-passthrough}

Our VMM, libvmm, supports AArch64 and x86-64 guests, exposing VirtIO devices
to the guest for storage and networking. On AArch64 we also support device passthrough.
On x86-64, passthrough requires handling devices on the PCIe bus, which we don't yet support.

We have a working prototype, but it isn't ready for public use. We're now
implementing a more principled version.

### More tutorials and guides {#tutorials}

One of the pieces of feedback we have received from online forums and following
the [seL4 Summit](https://sel4.systems/Summit/2026/) was that we need to provide
more guides to using LionsOS.

We are aiming to make a tutorial on how to build a basic system using LionsOS,
similar to building one of our [example systems](../examples) from scratch.

We'd also like to have similar tutorials for setting up libvmm, as well adding
new filters to the Firewall.

## Long term roadmap

The following are features we have experimented or are actively working on but are still a while
away from being available for use.

### More dynamicism

While LionsOS systems will always have a static architecture, we have worked on two areas
to improve the level of dynamicism that LionsOS supports.

The first is adapting sDDF drivers such that they can handle dynamic changes at the device level.
The main use-cases we are trying to support here are unplugging/plugging into an ethernet port
or SD card slot while the system is running.

The second is 'PD templates'. This is primarily a change within Microkit itself, and so you
can find more details on the [Microkit roadmap](https://docs.sel4.systems/projects/microkit/roadmap.html).

### Containers

We currently have a project that aims to turn LionsOS into a library OS that supports container-like
applications that can be spun up and destroyed on demand. This ties into the 'PD templates' feature
outlined above.

We are also interested in exploring using a [Web Assembly](https://webassembly.org/) runtime combined
with [WASI](https://wasi.dev/) to implement similar usability, but have not started working on this yet.

### Virtualisation

Our VMM, libvmm, can boot Linux on aarch64 and x86-64, and Windows 11 on x86-64.

Longer term, we plan to support:

* Multi-vCPU guests on x86-64 (already supported on aarch64).
* Windows guests on aarch64.
* RISC-V, which will also require implementing support for the RISC-V hypervisor extension in seL4 itself.