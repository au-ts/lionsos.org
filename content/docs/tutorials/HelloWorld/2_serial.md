---
weight: 3
bookFlatSection: false
title: "Serial"
---

# Part 2. Serial

In this stage of the tutorial, we will be walking you through setting up a
'meta program' through [sdfgen](https://au-ts.github.io/microkit_sdf_gen/sddf.html)
and allowing our Hello program to print through LionsOS serial. In the end
our system architecture will look like the following:

```txt
                                      ┌────────────────┐
                                ┌─────►   Hello PD     │
                                │     └────────────┬───┘
   ┌────────────────────────────┼──────────────────┼───────┐
   │                            │                  │       │
   │  LionsOS                   │                  │       │
   │                  ┌─────────┼──────────────────┼─────┐ │
   │                  │ ┌───────┼────────┐ ┌───────▼────┐│ │
   │                  │ │ Serial Virt Tx │ │ / Virt Rx  ││ │
   │                  │ └───────▲────────┘ └───────┬────┘│ │
   │                  │         │                  │     │ │
   │                  │         │                  │     │ │
   │                  │         │     ┌────────────▼───┐ │ │
   │                  │         └─────┼ Serial Driver  │ │ │
   │                  │               └──────┬─▲───────┘ │ │
   │                  └──────────────────────┼─┼─────────┘ │
   ┼─────────────────────────────────────────┼─┼───────────┤
   │                      seL4               │ │           │
   │                                         │ │           │
   └─────────────────────────────────────────┼─┼───────────┘   Software
 ────────────────────────────────────────────┼─┼──────────────
                                       ┌─────▼─┼──┐            Hardware
                                       │  UART    │
                                       └──────────┘

```

## Build System

We need to first build the drivers that we are going to integrate into the system.
The upstream documentation on connecting to [serial subsystem is available here](
https://github.com/au-ts/sddf/blob/main/docs/serial/serial.md#using-the-serial-subsystem).

<!-- FIXME: https://github.com/au-ts/sddf/pull/822 / LionsOS.mk? -->

We first need to add 'makefile snippets' telling the build system how to build
the serial components.

For serial components, the following need to appear after the 'common.mk' include.

```make
# Util - depended on by most sDDF drivers
include $(SDDF)/util/util.mk

# Serial Subsystem
include $(SDDF)/drivers/serial/$(UART_DRIV_DIR)/serial_driver.mk
include $(SDDF)/serial/components/serial_components.mk
```

Other driver classes follow similar patterns. We then need to tell make to
depend on the ELF files, so we can use them in our system:

```make
IMAGES := \
  serial_driver.elf \
  serial_virt_rx.elf \
  serial_virt_tx.elf \
  hello.elf
```

We need to then add a link-time dependency `libsddf_util_debug.a` to the sDDF
components. This file contains an implementation of `printf` that goes through
seL4's debug printing mechanisms.

```make
${IMAGES}: libsddf_util_debug.a

LIBS := --start-group -lmicrokit -Tmicrokit.ld libsddf_util_debug.a --end-group
```

At this point, you should be able to call `sddf_dprintf` (debug printf) in
`hello.c`. This still goes through the seL4 debug printing mechanisms, and so
won't work in release mode.

```c
#include <sddf/util/printf.h>

void init(void)
{
    sddf_dprintf("hello, world\n");
}
```

<!-- *Solution: Part 2a*. -->

Our next step is to link the 'hello' PD against our "proper" `sddf_printf` code,
which uses the serial subsystem of LionsOS/sDDF. This can be done by adding
`libsddf_util.a` as a dependency of `hello.elf` in the build system:

```make
hello.elf: hello.o libsddf_util.a
  $(LD) $(LDFLAGS) $^ $(LIBS) -o $@
```

There's a slight problem, though: this crashes.

```c
MON|ERROR: VMFault: ip=0x0000000000202720  fault_addr=0x0000000000000000  fsr=0x0000000093cb8006  (data fault)
MON|ERROR:   ec: 0x00000024  Data Abort from a lower Exception level   il: 1   iss: 0x01cb8006
MON|ERROR:   dfsc = translation fault, level 2 (0x00000006)
```

## Meta Program

There are a few things going wrong now. Despite us *building* the sDDF components,
the seL4 Microkit tool knows nothing about them: our 'System Description File'
`hello_world.system` still contains nothing but the 'Hello' PD. None of our
drivers or OS-level components have been included. Also, since we communicate
to the serial subsystem using shared queues, Microkit must be told to create
these shared queues, and our 'Hello' PD told where in memory it is located.
The fault then, is because when we do not tell a PD where the queue is, it
assumes that it is at address 0x0 and thus faults when we try to print.

Our solution to this is a 'Meta program', which allows us to create higher
level abstractions around the components which make up LionsOS.

Start by removing `hello_world.system`, and create a `meta.py` file.

In `hello_world.mk`, you'll want to declare the following rules:

```make
METAPROGRAM := $(TOP)/meta.py
# Remove "$(TOP)" from this, so it appears in the build folder
SYSTEM_FILE := hello_world.system

# ...

$(SYSTEM_FILE): $(METAPROGRAM) $(IMAGES) $(DTB)
  PYTHONPATH=$(SDDF)/tools/meta:$$PYTHONPATH \
    $(PYTHON) $(METAPROGRAM) --sddf $(SDDF) --board $(MICROKIT_BOARD) \
    --dtb $(DTB) --output . --sdf $(SYSTEM_FILE)
```

Now, let's fill out the meta program. We first need to import `sdfgen`, our tool
that provides sDDF/LionsOS/Microkit abstractions. You can see its [API documentation
here](https://au-ts.github.io/microkit_sdf_gen/). We then import the list of
supported boards from `$(SDDF)/tools/meta/board.py` which tells us information
about the board we are using.

```py
import argparse

from sdfgen import SystemDescription, Sddf, DeviceTree
from board import BOARDS

ProtectionDomain = SystemDescription.ProtectionDomain
```

Then, we write our `generate()` function. Here, we imperatively define the
contents of our System Description File. You may want to reference this against
what we previously had in `hello_world.system`. We add a Protection Domain called
'hello' using the 'hello.elf' file we build in Make, of priority 1, and then
we emit the `.system` XML into our build folder.

```py
def generate(sdf_file: str, output_dir: str, dtb: DeviceTree):
    hello = ProtectionDomain("hello", "hello.elf", priority=1)

    sdf.add_pd(hello)

    with open(f"{output_dir}/{sdf_file}", "w+") as f:
        f.write(sdf.render())
```

What follows is some boiler plate to parse arguments, read in the DTB file (the
Device Tree Blob), and then call `generate()`.

```py
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dtb", required=False)
    parser.add_argument("--sddf", required=True)
    parser.add_argument("--board", required=True, choices=[b.name for b in BOARDS])
    parser.add_argument("--output", required=True)
    parser.add_argument("--sdf", required=True)

    args = parser.parse_args()

    board = next(filter(lambda b: b.name == args.board, BOARDS))

    sdf = SystemDescription(board.arch, board.paddr_top)
    sddf = Sddf(args.sddf)

    with open(args.dtb, "rb") as f:
        dtb = DeviceTree(f.read())

    generate(args.sdf, args.output, dtb)
```

Now, when we run `make`, our build folder should contain a generated `.system`
file (`build/hello_world.system`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<system>
    <protection_domain name="hello" priority="1">
        <program_image path="hello.elf" />
    </protection_domain>
</system>
```

<!-- Solution 2b -->

## Connecting Serial

Now, follow the [sDDF documentation](https://github.com/au-ts/sddf/blob/main/docs/serial/serial.md#using-the-serial-subsystem). Connect up the serial subsystem and adjust
the the `hello.c` to initialise the queues and then print. This requires makefile,
meta.py, and C changes.

<!-- Solution 2c -->

Once you've done that, you should see the following output:

```txt
MON|INFO: Microkit Monitor started!
Begin input
'hello' is client 0
hello, world
```
