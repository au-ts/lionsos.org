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
$ export MICROKIT_SDK=$(realpath ../microkit-sdk-{{< microkit_version >}})
$ export LIONSOS=$(realpath ../lionsos)
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

You'll notice that the provided files contains a Microkit '.system' file. If you've
read the [seL4 Microkit tutorial] before, you might recognise it.
The 'System Description File' contains a mid-level description of PDs
('Protection Domains', analagous to processes), virtual memory mappings,
and communication channels. These are translated by the Microkit tool into a
[capDL image](https://docs.sel4.systems/projects/capdl/) which initialises the
set of *capabilities* given to applications running on top of seL4.


<!-- FIXME: Can we source the files and co-build the tutorial + docsite to reduce duplication? -->

Currently, the `.system` file is quite empty. All it says currently is that we
have one PD, called 'hello', which runs the image `hello.elf`.

```xml
<!-- hello_world.system -->

<system>
    <protection_domain name="hello">
        <program_image path="hello.elf" />
    </protection_domain>
</system>
```

`hello.elf` is produced by our `hello_world.mk` Makefile from this C program.
Right now, this does not use the features of LionsOS, and instead calls
`seL4_DebugPutString` via `microkit_dbg_puts`. The debug configuration of seL4
contains a basic (slow) UART driver which we can use. Of course, this does not work
in release mode (try running `make MICROKIT_CONFIG=release qemu` !).

```c
// hello.c

void init(void)
{
    microkit_dbg_puts("hello, world\n");
}

void notified(microkit_channel ch)
{
}
```


Something else to note is that protection domains are single-threaded, event-handler
style programs.[^1] This is facilitated with the `init()`, `notified()`, and
`protected()` entrypoints. If this is confusing to you, we recommend reading
the [seL4 Microkit tutorial].

[^1]: It is still possible to have multiple threads for a task, but this requires
      *explicit* shared memory concurrency. PDs are share-nothing by default.

[seL4 Microkit tutorial]: https://docs.sel4.systems/projects/microkit/tutorial/welcome.html


[Next](../2_serial), we'll be setting up a connection to our LionsOS serial
subsystem, so that we can print outside of debug mode.
