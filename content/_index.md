---
title: Introduction
type: docs
---

# The Lions Operating System

LionsOS is a modular operating system for embedded systems with a focus on security and performance.
It is based on the formally verified seL4 microkernel.

LionsOS is aimed at embedded, IoT and cyberphysical systems and is designed to:
1. ... be formally verifiable,
2. ... remain adaptable to a wide class of use cases in the target domain,
3. ... and set the benchmark for performance of microkernel-based operating systems.

We aim to achieve all three goals by a highly modular yet ruthlessly performance-oriented design and strict adherence to the time-honoured KISS principle.

LionsOS is able to support a variety of cyberphysical and embedded applications including
high-security, safety-critical and real-time requirements. It is suitable to run on most
ARMv8, RISCV64 and x86_64 systems as long as a memory management unit (MMU) is present.
LionsOS can scale with hardware ranging from low-power single-board computers like the
Raspberry Pi 4 to high-performance desktop or server machines.

LionsOS is a concurrent multiprocessing operating system supporting mixed-criticality tasks.
Tasks can be single applications, components of OS services or even [virtual machines](https://github.com/au-ts/libvmm/).

Ideal applications may include:
* Robotics controller systems,
* Networking appliances such as [firewalls](/docs/examples/firewall/) and routers,
* Flight systems for autonomous aircraft,
* Forward-deployed IoT devices such as predictive maintenance devices,
* [Point of sales terminals](/docs/examples/kitty/),
* Trustworthy virtual machine management,
* Embedded software for smart appliances,
* Security co-processors and trusted firmware devices,
* Control and monitoring systems for critical infrastructure,
* Smart grid / smart city devices,
* Isolating and managing existing embedded applications within a virtual machine,
* ... and most general embedded systems.

LionsOS is being developed by the [Trustworthy Systems](https://trustworthy.systems) research
group at [UNSW Sydney](https://unsw.edu.au) in Australia.

<!-- TODO: add architecture picture -->
<img src="/lionsos_arch.svg" alt="Architecture of a LionsOS-based system" />

<!-- TODO: need more fundamentals explained -->

All tasks in LionsOS including OS components are implemented and composed using the
[seL4 Microkit](https://github.com/seL4/microkit), a framework for statically architected
seL4 systems. All such tasks execute purely in userspace, including the set of drivers supplied by the
[seL4 Device Driver Framework](https://github.com/au-ts/sddf) (sDDF). User programs typically can avoid
all direct seL4 operations and can instead use the simplified interface of the Microkit, greatly lowering
the barriers for software development on LionsOS when compared to OSes using the raw seL4 interface.

The sDDF follows design principals mirroring LionsOS and offers a comprehensive library of drivers and
associated OS service protocols, such as:
* Ethernet driver,
* Serial (UART) driver,
* Peripheral timer driver,
* I2C host driver,
* Block device driver,
* VirtIO graphics driver.

LionsOS systems are constructed using the principals described
in the [sDDF design document](https://trustworthy.systems/projects/drivers/sddf-design-latest.pdf).

<!--- Note: the below is as Ivan left it, but I think this might not be a good statement of the principals given that
it's really just the sDDF principals and LionsOS can do more!--->
In brief, these are as follows:
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

LionsOS is currently in development and many more components will be introduced with time.
Pull requests to the various associated repositories are welcome. See the
[page on contributing](/docs/contributing) for more details.

{{< hint info >}}
LionsOS is currently undergoing active research and
development, it does not have a concrete verification story yet.

It is not expected for LionsOS to be stable at this time, but it
is available for others to experiment with.
{{< /hint >}}

<!---TODO: add link to FAQ here --->
