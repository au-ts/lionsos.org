---
weight: 1
bookToC: false
title: "0.4.0"
---

# {{< param title >}}

You can find the tag and associated downloads on [GitHub](https://github.com/au-ts/lionsos/releases/tag/{{< param title >}}).

## Release notes

<div style="width: 75%">

### General

* Update to [Microkit 2.3.0](https://github.com/seL4/microkit/releases/2.3.0),
  which includes seL4 16.0.0.
* Update to [sDDF 0.7.0](https://github.com/au-ts/sddf/releases/0.7.0),
  [libvmm 0.2.0](https://github.com/au-ts/libvmm/releases/0.2.0) and
  [MicroPython 1.26.1](https://github.com/micropython/micropython/releases/tag/v1.26.1).
* Example systems now inherit their toolchain setup from sDDF's `tools/make`
  snippets, so they can be built with GCC by setting `TOOLCHAIN=gcc`. Clang
  remains the default, and the `vmm` example still requires it.
* The Nix flake follows the stable `nixos-25.05` channel instead of
  `nixos-unstable`.
* Add `MAINTAINERS.md` to document component ownership and maintainers across the repository.

### Breaking changes

* The required `sdfgen` version is now 0.35.0.
* The minimum Python version is now 3.12.
* Components link against a musl-based libc instead of the minimal libc that
  sDDF provides.
* The POSIX, socket and file system helper libraries have moved out of the NFS
  client and the MicroPython component into `lib/`.

### POSIX support

Running unmodified POSIX code on LionsOS previously required linking against a
minimal shim inside the NFS client (originally written just to build `libnfs`).
We have extracted and expanded that shim into a standalone library any
component can use, adding broader file and socket support (client and server,
blocking and non-blocking), memory allocation, and time. File system
protocol status codes are now mapped directly to standard POSIX error numbers.

The [libc documentation](/docs/use/language_support/libc/) describes what is and
is not supported.

### WebAssembly

* Add an example system that runs the
  [WebAssembly Micro Runtime](https://github.com/bytecodealliance/wasm-micro-runtime)
  on top of the POSIX library, with access to both a file system and the
  network.
* The `wasi-sdk` toolchain is provided by the Nix flake.

### File systems

* The file system protocol has more precise error cases, so clients can
  determine why a command failed.
* The NFS component builds against upstream `libnfs` rather than a patched
  fork.
* Various minor fixes to the FAT and NFS components.

### MicroPython

* Rework I²C support to use the new sDDF I²C protocol through the non-blocking
  `libi2c` API.
* Use sDDF's `lib_sddf_lwip` for networking instead of the component's own lwIP
  port.
* Improve the keyboard interrupt implementation.
* Fix RISC-V builds.

### Examples

* Add POSIX and WebAssembly test systems that exercise file and socket
  functionality, and run them in CI along with the other examples.
* Kitty: use MMIO rather than PCI for the virtIO GPU on QEMU, simplifying
  passthrough configuration for the framebuffer VM.
* Example metaprograms use sDDF's shared board definitions instead of carrying
  their own copies.
* On QEMU, lwIP no longer performs address conflict detection, which noticeably
  shortens the time an example takes to get a DHCP lease.

</div>
