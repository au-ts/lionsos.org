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
pip3 install sdfgen=={{< sdfgen_version >}}
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
pip3 install sdfgen=={{< sdfgen_version >}}
```
{{% /tab %}}
{{% tab "Arch" %}}
```sh
sudo pacman -Sy make clang lld dtc python3 python-pip
# If you see 'error: externally-managed-environment', add --break-system-packages
pip3 install sdfgen=={{< sdfgen_version >}}
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

The firewall is a highly modular and configurable LionsOS system. It supports
configuration of the following:
* Platform (QEMU virt AArch64 or Compulab IOT-GATE-IMX8PLUS)
* Number of network interfaces (minimum 2), and their IP addresses and subnets
* Number and type of IP protocol filter components (UDP, TCP and ICMP provided)
* Initial filtering rules and routing table routes (these can also be modified
  at run-time)
* The capacity of each data structure used by firewall components

To enable this configurability without requiring the modification of C source
files, the firewall's [metaprogram](../releases/0.3.0/#metaprogram-tooling)
(`examples/firewall/meta.py`) utilises the Python `sdfgen` tooling, along with a
number of custom firewall Python modules. These modules can be found in the
`pyfw` directory (`examples/firewall/pyfw/`) and will be explained below.

### System configuration data

Build-time system configuration data is passed to LionsOS components via
*configuration structs*. Due to the high degree of complexity of the firewall
and the speed at which connections between components are changing, the firewall
defines a large number of _firewall configuration structs_
(`include/lions/firewall/config.h`) which are not yet incorporated into the
`sdfgen` module, as is typically the case for sDDF configuration data.

Each firewall component which depends on one or more of these structs defines a
section in their C file,  see the ICMP filter component
(`examples/firewall/filters/icmp_filter.c`):

```c
__attribute__((__section__(".fw_filter_config"))) fw_filter_config_t filter_config;

// This section holds an uninitialised copy of the filter config struct below
typedef struct fw_filter_config {
    uint8_t interface;
    fw_connection_resource_t router;
    region_resource_t internal_instances;
    region_resource_t external_instances[FW_MAX_INTERFACES];
    uint8_t num_external_instances;
    uint16_t instances_capacity;
    fw_webserver_filter_config_t webserver;
    region_resource_t rule_id_bitmap;
    fw_connection_resource_t icmp_module;
    fw_rule_t initial_rules[FW_MAX_INITIAL_FILTER_RULES];
    uint8_t num_initial_rules;
} fw_filter_config_t;
```

The metaprogram then calculates what data should be in each field, creates a
data file containing an _initialised_ struct, then copies this initialised
struct into the component's `.elf` file.

In the case of sDDF configuration structs (for example,
`dep/sddf/include/sddf/network/config.h`), the `sdfgen` module encapsulates the
calculation and serialisation of the struct, and emits a data file through an
API. However for the firewall, the metaprogram performs these operations without
using the `sdfgen` module. This is why the firewall's metaprogram, and
corresponding modules, are so much lengthier than the metaprogram of other
LionsOS systems.

To enable the accurate serialisation of these configuration structs, i.e. ensure
that the size and type of each struct field initialised by the metaprogram
correctly reflects what is given in the C configuration file, we have created a
Python script `sdfgen_helper.py`.

The `sdfgen_helper.py` script runs prior to the `metaprogram.py`, and generates
a python module named `config_structs.py` which defines a Python class for each
configuration struct defined in the C config file. Any updates to the C
`config.h` struct file will be reflected in the generated python module during
the next build, and will likely require updates to the metaprogram and the
`pyfw` modules which use the `config_structs` APIs.

### Metaprogram system configuration

Most of the configurable system properties listed in the [metaprogram
introductory section](#firewall-metaprogram) are set in the Python constants
file (`examples/firewall/pyfw/constants.py`). This includes board information,
networking constants, as well as data structure capacities. Essentially all
properties of the firewall that are designed to be configurable per running
instance can be set here.

If you wish to update the connections between components, or add a new
component, check the [metaprogram component files](#metaprogram-component-files)
section.

#### Network constants

The network settings of each network interface (or NIC) are represented by the
NetworkInterface class, the definition can be found in
`examples/firewall/pyfw/component_net_interface.py`:

```py
@dataclass
class NetworkInterface:
    index: int
    name: str
    board_ethernet: str
    mac: Tuple[int, ...]
    ip: str
    subnet_bits: int
    priorities: InterfacePriorities = field(default_factory=InterfacePriorities)

    @property
    def ip_int(self) -> int:
        import ipaddress

        ip_split = self.ip.split(".")
        ip_split.reverse()
        reversed_ip = ".".join(ip_split)
        return int(ipaddress.IPv4Address(reversed_ip))

    @property
    def mac_list(self) -> List[int]:
        return list(self.mac)
```

Each network interface must be given an `index` integer (starting from 0). This
number is used to select which ethernet device the software interface
corresponds to (the network interface with index 0 uses `ethernet0`).
Additionally, the index is used as an identifier for all network components
receiving packets from this interface, as well as for the interface's Rx DMA
buffers so they can be returned after forwarding.

In `constants.py`, the `interfaces` array lists each network interface of the
firewall - by default there are two interfaces listed. For each network
interface, all interface specific network components (virtualisers, filters, ARP
components) will be duplicated with the value of the interfaces's `index`
appended to their elf and Microkit names.

### Metaprogram component files

Each component in the firewall is represented by a python class which encodes
the component's connections with other components, as well as build time
configuration information. Each class defines two mandatory methods:
- `__init__`: The special Python method for creating an instance of the class.
  As arguments, this function takes fixed instance specific constants like
  interface index and process priority. Within this function any required class
  book-keeping is maintained, and any memory regions that the instance needs to
  function correctly are generated.
- `finalise_config`: This method ensures that all the configuration data has
  been initialised correctly, so typically involves a number of asserts. The
  method is called prior to the configuration data file being created.

Each component is a child class of the corresponding Python configuration class
in the [sdfgen helper](#system-configuration-data) generated module
`config_structs.py`. For example, the ARP requester component class defined in
`examples/firewall/pyfw/component_arp.py`:

```py
class ArpRequester(Component, FwArpRequesterConfig):
```

has as a child class the `FWArpRequesterConfig` which encodes the
`fw_arp_requester_config_t` struct defined in `config.h`. This allows each
component to fill in and add to the fields of the struct as connections are
established and memory regions are generated.

In addition to the required methods, each class may implement various methods
for connecting instances to other components. For example, the ARP requester
class has a method for adding a client (i.e. a component that can make ARP
requests):

```py
    def add_arp_client(
        self,
        client: Component,
    ) -> FwArpConnection:
```

The method:
1. Generates the ARP queue memory regions (one for requests, another for
   responses).
2. Maps the regions into the ARP requester and client.
3. Creates a channel for the components to signal each other on.
4. Appends the client information (queue addresses, capacity and channel number)
   to the ARP requester's internal list of clients.
5. Returns the information needed by the client (queue addresses, capacity and
   channel number).

Each component class implements different methods for connecting with other
components. Connections between components are *always* created using class
methods, with only one exception (the instance regions of filters of the same
protocol are mapped into each others address space in the `finalise_config`
method).

Instances of component classes, and connections between them, are all created in
the [metaprogram](#metaprogram-file) itself.

#### Data structure sizes and capacities

Due to the static nature of systems built using the Microkit framework, all
memory regions are defined and sized at build time. However this requires
calculating in one way or another the number of bytes required for a given data
structure. For example, in the router we have:

```C
typedef struct fw_routing_entry {
    /* ip address of destination subnet */
    uint32_t ip;
    /* number of bits in subnet mask */
    uint8_t subnet;
    /* interface subnet traffic should be transmitted through */
    uint8_t interface;
    /* ip address of next hop */
    uint32_t next_hop;
} fw_routing_entry_t;

typedef struct fw_routing_table {
    /* capacity of table */
    uint16_t capacity;
    /* number of valid entries in table */
    uint16_t size;
    /* routing table entries stored consecutively */
    fw_routing_entry_t entries[];
} fw_routing_table_t;

```

As you can see, we do not enforce in the C code the capacity of the routing
table (or size of the `entries` array). Instead, the router is given the
capacity of the table as an entry in it's configuration struct
`fw_router_config_t`. However, this does not solve the issue of ensuring that we
have generated a memory region large enough to contain the entire routing table.

For this, we use the memory layout module
(`examples/firewall/pyfw/memory_layout.py`) which provides the
`FirewallMemoryRegions` and `FirewallDataStructures` classes. The
FirewallMemoryRegion class represents a memory region which can contain zero or
more FirewallDataStructure instances, representing data structures defined in
the firewall codebase.

In the example above, the `fw_routing_table_t` and the `fw_routing_entry_t` are
the data structures that are held within the routing table memory region:

```py
routing_table_wrapper = FirewallDataStructure(
    elf_name="routing.elf", c_name="fw_routing_table"
)
routing_table_buffer = FirewallDataStructure(
    elf_name="routing.elf", c_name="fw_routing_entry", capacity=256
)
routing_table_region = FirewallMemoryRegions(
    data_structures=[routing_table_wrapper, routing_table_buffer]
)
```

See (`examples/firewall/pyfw/constants.py`) for further examples of data
structures and regions.

To extract the size of each FirewallDataStructure and thus calculate the size of
each FirewallMemoryRegion instance, we parse each elf file's dwarf information
directly and read the size and alignment of each data structure type.

The `FirewallMemoryRegions` and `FirewallDataStructure` class instance variables
work as follows:

```py
FirewallMemoryRegions(unaligned_size = None,
                      dependent_type_info: List[FirewallDataStructure]|None = None,
                      region_size_formula = lambda list: sum(item.get_size() for item in list))
```
- `unaligned_size`: The (non page aligned) size of the region if known. If this
  is provided the size calculation phase will be bypassed.
- `dependent_type_info`: The data structures contained within this memory
  region.
- `region_size_formula`: The formula used to calculate the overall size of the
  region from the dependent data structures. By default computes region size =
  sum(dependent_type_info.size).

```py
FirewallDataStructure(size: int|None = None,
                      entry_size:int|None = None,
                      capacity:int|None = None,
                      size_formula_bytes = lambda x: x.entry_size * x.capacity,
                      elf_name = None,
                      c_name = None)
```
- `size`: The total size of the data structure if known. If this is provided,
  both the elf extraction phase and size calculation phase will be bypassed.
- `entry_size`: The size of an array entry. Either set on instantiation or
  extracted by the metaprogram.
- `capacity`: The capacity of the array to be held in this region.
- `size_formula_bytes`: The formula for calculating the size of the data
  structure held in this region, by default computes size = entry size *
  capacity.
- `elf_name`: The name of the elf file to find the dwarf information.
- `c_name`: The name of the variable in `{elf_name}` that contains the size of
  the array entry.

### Metaprogram file

The firewall metaprogram (`examples/firewall/meta.py`) is the file which *uses*
all the modules listed above. By reading the configuration information given in
`constants.py`, it creates all the required components and connections between
them. This essentially boils down to creating the underlying Microkit objects
through the `sdfgen` module, emitting a configuration file (`*.data`) for each
component, and initialising the sections in each `.elf` file. Additionally, the
metaprogram ensures the a Microkit system file is emitted.

## Next steps

If you have successfully compiled the system, there should be an image file in
the build directory, the default location being
`examples/firewall/build/firewall.img`.

You can now move to running the system in [Docker](../docker) or
[hardware](../running).
