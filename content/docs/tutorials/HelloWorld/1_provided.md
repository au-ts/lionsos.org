---
weight: 2
bookFlatSection: false
title: "Provided Code"
---

# Part 1. Provided Code

We initially provide you with a basic [seL4 Microkit](https://docs.sel4.systems/projects/microkit/)
code example, for you to confirm your build system is correctly set up.

Now, enter the folder for our tutorial ('Hello World').


```sh
$ cd lionsos_tutorial
$ ls
lionsos/  microkit-sdk-{{< microkit_version >}}/  hello_world/  ...
$ cd hello_world
$ ls
hello_world.mk  Makefile  README.md  src/  ...
```

Start by building the initial code skeleton:

```sh
$ export MICROKIT_SDK=../microkit-sdk-{{< microkit_version >}}
$ export LIONSOS=../lionsos
$ # You only need to run this once to setup the submodules
$ make submodules
$ make
```

And then, run the provided code in QEMU:

```sh
$ make qemu
...
LDR|INFO: loader for seL4 starting
...
Booting all finished, dropped to user space
INFO  [sel4_capdl_initializer::initialize] Starting CapDL initializer
INFO  [sel4_capdl_initializer::initialize] Starting threads
MON|INFO: Microkit Monitor started!
hello, world
```

You will need to press Ctrl+a, then x, to exit QEMU.

The primary difference to one of the packaged examples within the Microkit SDK
is that we utilise the LionsOS/sDDF common board files. These give us definitions
of the `$(CC)`, `$(LD)`, as well as other board-specific information such as the
names of the ELF files that our sDDF drivers use.

```make
include $(SDDF)/tools/make/board/common.mk
# calls...
# ... include $(SDDF)/tools/make/board/$(MICROKIT_BOARD).mk
# ... include $(SDDF)/tools/make/toolchain/$(TOOLCHAIN).mk
```
