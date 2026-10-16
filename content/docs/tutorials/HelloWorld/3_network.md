---
weight: 4
bookFlatSection: false
title: "Network"
---

# Part 3. Network

This part involves hooking up a new client, called 'memcached' to the network
and serial subsystems of LionsOS.

```txt


          ┌─────────────┬─────────┐
          │   ┌────────►│Memcached┼──────────┐
          │   │         └┬──▲─────◄─────────┐│
   ┌──────┼───┼──────────┼──┼───────────────┼┼─────────────┐
   │      │   │          │  │               ││             │
   │  ┌───▼───┴──┐     ┌─▼──┼──────┐      ┌─┘▼─────────┐   │
   │  │          │     │           │      │            │   │
   │  │  Timer   │     │  Network  │      │   Serial   │   │
   │  │          │     │           │      │            │   │
   │  └──────────┘     └───────────┘      └────────────┘   │
   │                                                       │
   │                       LionsOS                         │
   ├───────────────────────────────────────────────────────┤
   │                                                       │
   │                         seL4                          │
   └───────────────────────────────────────────────────────┘


```

Follow the documentation on [Using the network subsystem](
https://github.com/au-ts/sddf/blob/main/docs/network/network.md#using-the-network-subsystem)
for the structure of what is needed to add to your system.

You'll want to set up:

*   A new C/ELF program called 'memcached.elf', with an new source file (we suggest
    renaming 'hello.c'!)

*   The additions to the Makefile to build the ethernet driver, timer driver,
    and the network virtualisers.

*   The additions to meta.py to create PDs for the driver/virtualisers, and
    to initialise an `Sddf.Net`, `Sddf.Timer`, and `Sddf.Lwip` component.
    Then, the addition `OBJCOPY` to patch the `_config` data into the PDs.

*   Calls to `net_queue_init`, `net_buffers_init`, and `sddf_lwip_init`, as well
    as the new `#include` and global variables.

*   A new include directory added to `CFLAGS` which uses `LWIPDIR`, a Make variable
    defined after you include the `lib_sddf_lwip.mk` snippet.

    ```make
        -I$(LWIPDIR)/include \
        -I$(LWIPDIR)/include/ipv4 \
    ```

*   You'll also need a copy of the `lwipopts.h` file, to include. We suggest
    taking the [copy from sDDF echo server](https://github.com/au-ts/sddf/blob/main/examples/echo_server/include/lwip/lwipopts.h), and it to the `CFLAGS` as well.

<!-- TODO: more explanation of how this all works? IDK -->
