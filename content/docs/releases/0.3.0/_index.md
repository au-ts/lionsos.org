---
weight: 10
bookToC: false
title: "0.3.0"
---

# {{< param title >}}

You can find the tag and associated downloads on [GitHub](https://github.com/au-ts/lionsos/releases/tag/{{< param title >}}).

## Release notes

<div style="width: 75%">

* Update to [Microkit 2.0.1](https://github.com/seL4/microkit/releases/2.0.1).
* Update to [sDDF 0.6.0](https://github.com/au-ts/sddf/releases/0.6.0).
* Update to [libvmm 0.1.0](https://github.com/au-ts/libvmm/releases/0.1.0).
* Add FAT file system support.
* Add QEMU (AArch64) support for the Kitty example system.
* Various improvements to the file system protocol and client library.
  * In general the library is now more explicit and supports batch processing
    of commands and completions.
* Add file system server library to make it easier to implement
  file systems.
* Fixes and stability improvements across various components such as NFS, MicroPython,
  and the web server.

### Metaprogram tooling

One of the main issues we found with our current approach to using LionsOS was
the time and effort needed to simply stitch together components into one coherent
system.

For the last couple of months we have been working on providing new tooling to
address this friction and make it easier for people to take our off-the-shelf
components and make their own system.

This release transitions our components and example systems to use that tooling.
Each component no longer has system-dependent information hard-coded into the ELF
via C headers and instead injected after compilation. This way off-the-shelf components
are not dependent on the user's specific system.

This is done via a 'metaprogram', a program written by the user which describes their
system, what components exists, what I/O systems exist, etc.

The tooling is still experimental, and we are actively developing it to improve and mature
it.

</div>
