---
title: Introduction
type: docs
---

# The Lions Operating System

{{< hint info >}}
LionsOS is currently undergoing active research and
development, it does not have a concrete verification story yet.

It is not expected for LionsOS to be stable at this time, but it
is available for others to experiment with.
{{< /hint >}}

LionsOS is an operating system based on the [seL4 microkernel](https://sel4.systems)
with the goal of making the achievements of seL4 accessible. That is,
to provide performance, security, and reliability.

LionsOS is being developed by the [Trustworthy Systems](https://trustworthy.systems) research
group at [UNSW Sydney](https://unsw.edu.au) in Australia.

<!-- TODO: add architecture picture -->
<img src="/lionsos_arch.svg" alt="Architecture of a LionsOS-based system" />

<!-- TODO: need more fundamentals explained -->

It is not a conventional operating system, but contains composable
components for creating custom operating systems that are specific to
a particular task.  Components are joined together using the
[Microkit](https://github.com/seL4/microkit) tool.

The principles on which a LionsOS system is built are laid out fully
in the [sDDF design document](https://trustworthy.systems/projects/drivers/sddf-design-latest.pdf); but in brief they
are:
1. Components are connected by lock-free queues using an efficient
   model-checked signalling mechanism.

1. As far as is practical, operating systems components do a single
   thing. Drivers for instance exist solely to convert between a
   hardware interface and a set of queues to talk to the rest of the
   system.

1. Components called
   _virtualisers_ handle multiplexing and control, and conversion
   between virtual and IO addresses for drivers.

1. Information is shared only where necessary, via the queues, or via
   published information pages.

1. The system is static: it does not adapt to changing hardware, and
   does not load components at runtime.  There is a mechanism for
   swapping components _of the same type_ at runtime, to implement
   policy changes, or to reboot a virtual machine with a new Linux
   kernel.

To be successful, many more components are needed.  Pull requests to
the various repositories are welcome. See the
[page on contributing](/docs/contributing) for more details.
