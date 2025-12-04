+++
title = 'Building'
draft = false
weight = 10
+++

# Building

{{< hint info >}}
The firewall example currently relies on Microkit changes that are not part of a released version.
If you have previously setup your machine for LionsOS before make sure to follow the instructions
for acquiring the pre-release version of Microkit below.

<br>
Once the next Microkit release is out, we will pin to that instead.
{{< /hint >}}

## Acquire source code

```sh
git clone https://github.com/au-ts/lionsos.git
cd lionsos
```

## Dependencies

Run the following commands depending on your machine:
{{% tabs "dependencies" %}}
{{% tab "Ubuntu/Debian" %}}
```sh
sudo apt update && sudo apt install make cmake clang lld llvm device-tree-compiler unzip git qemu-system-arm python3 python3-pip
# If you see 'error: externally-managed-environment', add --break-system-packages
pip3 install sdfgen==0.26.0
```
{{% /tab %}}
{{% tab "macOS" %}}
```sh
# Make sure that you add the LLVM bin directory to your path.
# For example:
# echo export PATH="/opt/homebrew/Cellar/llvm/bin:$PATH" >> ~/.zshrc
# Homebrew will print out the correct path to add
brew install make dtc llvm qemu
# If you see 'error: externally-managed-environment', add --break-system-packages
pip3 install sdfgen==0.26.0
```
{{% /tab %}}
{{% tab "Arch" %}}
```sh
sudo pacman -Sy make clang lld dtc python3 python-pip
# If you see 'error: externally-managed-environment', add --break-system-packages
pip3 install sdfgen==0.26.0
```
{{% /tab %}}
{{% tab "Nix" %}}
```sh
nix develop
```
{{% /tab %}}
{{% /tabs %}}

### Acquire the Microkit SDK

Run the following commands depending on your machine:
{{% tabs "microkit-sdk" %}}
{{% tab "Linux (x64)" %}}

```sh
wget https://trustworthy.systems/Downloads/microkit/microkit-sdk-{{< microkit_version_firewall >}}-linux-x86-64.tar.gz
tar xf microkit-sdk-{{< microkit_version_firewall >}}-linux-x86-64.tar.gz
```
{{% /tab %}}
{{% tab "macOS (ARM64)" %}}
```sh
wget https://trustworthy.systems/Downloads/microkit/microkit-sdk-{{< microkit_version_firewall >}}-macos-aarch64.tar.gz
tar xf microkit-sdk-{{< microkit_version_firewall >}}-macos-aarch64.tar.gz
```
{{% /tab %}}
{{% tab "macOS (x64)" %}}
```sh
wget https://trustworthy.systems/Downloads/microkit/microkit-sdk-{{< microkit_version_firewall >}}-macos-x86-64.tar.gz
tar xf microkit-sdk-{{< microkit_version_firewall >}}-macos-x86-64.tar.gz
```
{{% /tab %}}
{{% /tabs %}}

## Compiling the firewall system

Before compiling the firewall system, it is important that you first update the
[system wide configuration constants](#firewall-system-constants) that will be
used in all firewall components. These can be found at the top of the
[metaprogram](#firewall-metaprogram).

You may also wish to toggle the debug printing of firewall components on or off.
Debug printing is helpful as it provides a trace of all packets through the
firewall, however the large number of printing components tend to interfere with
each other and cause a high degree of latency through the system. The macro used
to toggle debug printing is `FW_DEBUG_OUTPUT` and can be found in
`include/lions/firewall/config.h`.

If you wish to run the firewall on QEMU inside our Docker container that
emulates the required networking infrastructure, it is recommended that you
build the image for QEMU on your host machine and share it with the ubuntu
guest. This is faster and avoids having to install unnecessary dependencies in
the container. More detailed instructions on this can be found in the section on
[running on QEMU inside Docker](../docker).

{{% tabs "build" %}}
{{% tab "QEMU virt AArch64" %}}
```sh
cd examples/firewall
export MICROKIT_SDK=/path/to/sdk
# Platform to target
export MICROKIT_BOARD=qemu_virt_aarch64
make
```
{{% /tab %}}
{{% tab "Compulab IOT-GATE-IMX8PLUS" %}}
```sh
cd examples/firewall
export MICROKIT_SDK=/path/to/sdk
# Platform to target
export MICROKIT_BOARD=imx8mp_iotgate
make
```
{{% /tab %}}
{{% /tabs %}}

If you need to build a release version of the system, you must also specify:
```sh
make MICROKIT_CONFIG=release
```

Note that this will restrict serial output to components who have an explicit
sDDF serial subsystem connection. By default, this is only the webserver,
routers and ARP components.

## Firewall metaprogram

The firewall metaprogram (`examples/firewall/meta.py`) is responsible for
creating all the required Microkit objects and sDDF connections. It also creates
`.data` files containing serialised encodings of this data for all the
protection domains in the system. We then `objcopy` these `.data` files into
each `.elf` file, either in the metaprogram itself or in the makefile
`firewall.mk`.

Due to the high degree of complexity of the firewall, and the vast number of
connections between components, the firewall system defines a large number of
_firewall configuration structs_: `include/lions/firewall/config.h`. Typically,
for most LionsOS systems, this complexity is hidden within the `sdfgen` module.
However, since the firewall is a new system, and the system information is still
under development, we handle the creation and serialisation of these `.data` files
in the metaprogram.

The `sdfgen_helper.py` script runs prior to the `metaprogram.py`, and generates
a python module named `config_structs.py` which defines a Python class for each
configuration struct defined in the C config file. Any updates to the
configuration struct file will be reflected in the generated python module
during the next build, and will likely require updates to the API used in the
metaprogram.

### Firewall system constants

The metaprogram is also where many system wide constants can be found, including
data structure capacities, local subnet information, IP addresses and MAC
addresses of the NICs. Any changes to these values will require the firewall
image to be rebuilt. These will need to be updated to match your
[Docker](../docker) or [hardware](../running) testing setup.

#### Network constants

The network configuration information can be found at the top of the
metaprogram:

```py
# System network constants
ext_net = 0
int_net = 1

macs = [
    [0x00, 0x01, 0xC0, 0x39, 0xD5, 0x18],  # External network
    [0x00, 0x01, 0xC0, 0x39, 0xD5, 0x10],  # Internal network
]

subnet_bits = [12, 24]  # External network, Internal network

ips = ["172.16.2.1", "192.168.1.1"]  # External network, Internal network
```

#### Data structure sizes and capacities

Data structure sizes and capacities are encoded using the
`FirewallMemoryRegions` and `FirewallDataStructure` classes. Currently all
instances of these classes are declared at the top of the metaprogram, with the
first as follows:

```py
# Firewall memory region and data structure object declarations, update region capacities here
fw_queue_wrapper = FirewallDataStructure(elf_name="routing.elf", c_name="fw_queue")

dma_buffer_queue = FirewallDataStructure(
    elf_name="routing.elf", c_name="net_buff_desc", capacity=512
)
dma_buffer_queue_region = FirewallMemoryRegions(
    data_structures=[fw_queue_wrapper, dma_buffer_queue]
)
```

These classes aim to simplify the process of creating the Microkit memory
regions needed to hold firewall data structures. Typically each memory region
contains one or more arrays of structs, and a collection of corresponding
metadata variables (like head and tail pointers) also held in structs. This
poses a challenge during development as the elements within these structs tend
to change frequently, and each time they change the size of the memory region
used to hold them needs to be recalculated.

To address this issue, we extract the size of these structs automatically by
parsing the dwarf information of an elf file containing their definitions. This
leaves the more complicated aspects of type sizing like struct alignment to the
build system. Firewall defined types are encoded in the `FirewallDataStructure`
class, which can then be used as building blocks for constructing a
`FirewallMemoryRegions` object.

`FirewallMemoryRegions` objects can be constructed in this 'building-block'
fashion by proving a list of `FirewallDataStructure` objects, or this can be
bypassed and a known fixed size can be provided. One the required size of the
region is known, it is used as the minimum region size and the final region size
is calculated by rounding up to the nearest page size.

The `FirewallMemoryRegions` and `FirewallDataStructure` class instance variables
work as follows:

```py
class FirewallMemoryRegions:
    def __init__(
        self,
        *,
        min_size: int = 0,
        data_structures: List[FirewallDataStructure] = [],
        size_formula=lambda list: sum(item.size for item in list),
    ):
```
- `min_size`: If provided, this size will bypass the `FirewallDataStructure`
  mechanism, and this value will be used for the minimum size of the region.
- `data_structures`: If `min_size` is not provided, this list, along with the
  size formula, will be used to calculate the minimum size. In particular, the
  size of each element in this list will be combined using the `size_formula`.
- `size_formula`: If `min_size` is not provided, this formula will be used to
  calculate the minimum size using the list of internal data structure. The
  formula should take this list as its only argument, and produce a minimum
  size. If a list is provided but a formula is not, a default formula of taking
  the sum of the size of each data structure will be use.

```py
class FirewallDataStructure:
    def __init__(
        self,
        *,
        size: int = 0,
        entry_size: int = 0,
        capacity: int = 1,
        size_formula=lambda x: x.entry_size * x.capacity,
        elf_name=None,
        c_name=None,
    ):
```
- `size`: The total size of the region if known. If this is provided, both the
  elf extraction phase and size calculation phase will be bypassed.
- `entry_size`: The size of an array entry. This can either set on instantiation
  or extracted from the `elf_name` elf file by searching for the type given by
  `c_name`.
- `capacity`: The capacity of the data structure, used in the case that the
  instance represents an array. This defaults to 1 in the case that the instance
  is just a single struct.
- `size_formula`: The formula used to calculate the overall size of the
  structure from the entry size and capacity. The formula takes an object of the
  class as a single argument and outputs a size. The default formula assumes
  that the size is given by the product of entry size and capacity.
- `elf_name`: The name of the elf file to find the dwarf type information.
- `c_name`: The name of the c struct type of the data structure. For example,
  when extracting the `fw_arp_entry` type, the c_name to use is `fw_arp_entry`,
  as shown in the code snippets below.

```py
arp_cache_buffer = FirewallDataStructure(
    elf_name="arp_requester.elf", c_name="fw_arp_entry", capacity=512
)
```

```c
typedef struct fw_arp_entry {
    /* state of this entry */
    uint8_t state;
    /* IP address */
    uint32_t ip;
    /* MAC of IP if IP is reachable */
    uint8_t mac_addr[ETH_HWADDR_LEN];
    /* bitmap of clients that initiated the request */
    uint8_t client;
    /* number of arp requests sent for this IP address */
    uint8_t num_retries;
} fw_arp_entry_t;
```

## Next steps

If you have successfully compiled the system, there should be an image file in
the build directory, the default location being
`examples/firewall/build/firewall.img`.

You can now move to running the system in [Docker](../docker) or
[hardware](../running).
