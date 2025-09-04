---
title: "I/O"
weight: 1
---

# Input/Output

The I/O done with LionsOS is all in user-space and is separated into components with
a single purpose.

## Device Drivers and Virtualisers

Device drivers are intended to take the hardware-specific interface with the device and
turn that into a standard interface based on its device class with the next component in the
chain, the virtualiser.

Virtualisers are components that are responsible for taking a single connection with the driver and
multiplexing between all the client connections.

There are other standard components that may or may not be involved depending on the design of your
system, one example is block device partitioner that sits between clients and the virtualiser, allowing
clients to only see a section of the device.

These components used in LionsOS come from the [seL4 Device Driver Framework](https://github.com/au-ts/sddf).

Currently sDDF offers a variety of device classes, such as:
* Serial
* Ethernet
* I<sup>2</sup>C
* Block

The design and goals of sDDF can be found [here](https://trustworthy.systems/projects/drivers/sddf-design-latest.pdf).

## Higher-level clients

In general, anything higher-level than a virtualiser that is a generic client is provided by LionsOS.

The main example of this is file systems.

### File Systems

Right now our work regarding file systems is quite rudimentary. We support the Network File System (NFS)
but are working on a FAT file system as well as an actual block device driver.
