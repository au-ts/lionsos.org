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

## Short term roadmap

Below are a couple projects we are actively working on and the general
direction we are taking for the next couple months.

### Better tooling

With [release 0.3.0](../releases/0.3.0) we introduced [metaprogramming tooling](../releases/0.3.0/#metaprogram-tooling)
to make it easier to develop a LionsOS system. There are still many areas to improve with this tooling
and are doing so as we use it more and more internally.

The two other main areas to help the usability of LionsOS is proper [GDB support](../use/debugging).
and [performance profiling](../use/profiling).

The profiler is still under-going a lot of experimentation but GDB support is close to being merged
in and available for use.

### x86-64 support

While we have support for various ARM and RISC-V platforms, there is community
interest for x86-64 support which we are actively working on.

This requires a number of changes to seL4 Microkit itself as well as basic drivers
such as ethernet and SATA/AHCI in sDDF.

We also working on porting our virtual-machine-monitor to support VMs on x86-64.

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

We are also interested in exploring using a Web Assembly runtime combined with WASI to implement
similar usability, but have not started working on this yet.
