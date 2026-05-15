---
weight: 30
bookCollapseSection: true
title: "GDB"
---

# GDB Example System

This is a showcase of using `libgdb` within a LionsOS system. This is currently
experimental pending the merging of seL4 and Microkit PR's.

This example connects to gdb on a target system over the network. Please
ensure that the target board is on a network and reachable by your host
machine. Alternatively, you can use QEMU to test out this demo.

# Components
Here as an overview of the architecture of this example:
![gdb example architecture](/LionsOS_GDB.svg)

**debugger component**

The debugger component is split up into 3 main parts:

***gdb.c***: This is the interface between the debugger and the
underlying GDB implementation. This component does things such as setting/unsetting
break points, reading from debuggee address space and generally handling all the GDB
commands passed from the user.

***debugger.c***: This is the interface between the user and `gdb.c`. This is where we
receive packets containing GDB commands over the network.

***libvspace***: This library provides the functionality to read/write to the debuggee
processes address space.

If you are interested in building and running it see the pages on:
* [Building](./building)
* [Running](./running)