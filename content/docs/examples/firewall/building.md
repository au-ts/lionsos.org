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

macs = [[0x00, 0x01, 0xc0, 0x39, 0xd5, 0x18], # External network
        [0x00, 0x01, 0xc0, 0x39, 0xd5, 0x10]] # Internal network

subnet_bits = [12, # External network
               24] # Internal network

ips = ["172.16.2.1",  # External network
       "192.168.1.1"] # Internal network
```

#### Data structure sizes and capacities

Data structure sizes and capacities are encoded using the
`FirewallMemoryRegions` class. Currently all instances of this class are
declared at the top of the metaprogram, with the first as follows:

```py
# Firewall memory region object declarations, update region capacities here
dma_buffer_queue_region = FirewallMemoryRegions("fw_buffer_queue_entry_size",
                                                512,
                                                lambda x: 16 + x.capacity * x.entry_size)
```

The `FirewallMemoryRegions` class is a rudimentary attempt to simplify the
generation of Microkit memory regions to hold shared firewall data structures,
most of which are arrays of structs. This can be challenging during development
as the structs being used as array elements tend to change frequently, and each
time they change the size of the memory region used to hold them needs to be
recalculated.

Our current solution to simplify this process is to extract the size of the
relevant structs from C variables defined in the routing component
`examples/firewall/routing/routing.c`, although we are [in the
process](https://github.com/au-ts/lionsos/issues/234) of updating this approach
to read the size of the struct directly from debug information in the `.elf`
file.

The `FirewallMemoryRegions` class instance variables work as follows:

```py
FirewallMemoryRegions(c_name, capacity, region_size_formula, entry_size = 0, region_size = 0)
```
- `c_name`: The name of the variable in `routing.elf` that contains the size of
  the array entry.
- `capacity`: The capacity of the array to be held in this region.
- `region_size_formula`: The formula for calculating the size of the data
  structure held in this region, typically based on entry size and capacity.
  This is useful for shared data structures containing an array as well as
  additional metadata information.
- `entry_size`: The size of an array entry. Either set on instantiation or
  extracted from `routing.elf` using `c_name`.
- `region_size`: The size of the region. Either set on instantiation or
  calculated using the `region_size_formula`.

## Next steps

If you have successfully compiled the system, there should be an image file in
the build directory, the default location being
`examples/firewall/build/firewall.img`.

You can now move to running the system in [Docker](../docker) or
[hardware](../running).
