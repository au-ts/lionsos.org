+++
title = 'Building'
draft = false
weight = 10
+++

# Building

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
pip3 install sdfgen==0.25.0
```
{{% /tab %}}
{{% tab "macOS" %}}
```sh
# Make sure that you add the LLVM bin directory to your path.
# For example:
# echo export PATH="/opt/homebrew/Cellar/llvm/16.0.6/bin:$PATH" >> ~/.zshrc
# Homebrew will print out the correct path to add
brew install make dtc llvm qemu
# If you see 'error: externally-managed-environment', add --break-system-packages
pip3 install sdfgen==0.25.0
```
{{% /tab %}}
{{% tab "Arch" %}}
```sh
sudo pacman -Sy make clang lld dtc python3 python-pip
# If you see 'error: externally-managed-environment', add --break-system-packages
pip3 install sdfgen==0.25.0
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
wget https://github.com/seL4/microkit/releases/download/{{< microkit_version >}}/microkit-sdk-{{< microkit_version >}}-linux-x86-64.tar.gz
tar xf microkit-sdk-{{< microkit_version >}}-linux-x86-64.tar.gz
```
{{% /tab %}}
{{% tab "macOS (ARM64)" %}}
```sh
wget https://github.com/seL4/microkit/releases/download/{{< microkit_version >}}/microkit-sdk-{{< microkit_version >}}-macos-aarch64.tar.gz
tar xf microkit-sdk-{{< microkit_version >}}-macos-aarch64.tar.gz
```
{{% /tab %}}
{{% tab "macOS (x64)" %}}
```sh
wget https://github.com/seL4/microkit/releases/download/{{< microkit_version >}}/microkit-sdk-{{< microkit_version >}}-macos-x86-64.tar.gz
tar xf microkit-sdk-{{< microkit_version >}}-macos-x86-64.tar.gz
```
{{% /tab %}}
{{% /tabs %}}

### Acquire the AArch64 toolchain

There is a choice of toolchains at [ARM Toolchains](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
We're currently using GCC 12.

{{% tabs "aarch64-toolchain" %}}
{{% tab "Linux (x64)" %}}

```sh
wget 'https://developer.arm.com/-/media/Files/downloads/gnu/12.3.rel1/binrel/arm-gnu-toolchain-12.3.rel1-x86_64-aarch64-none-elf.tar.xz?rev=a8bbb76353aa44a69ce6b11fd560142d&hash=20124930455F791137DDEA1F0AF79B10' \
    -O arm-gnu-toolchain-12.3.rel1-aarch64-none-elf.tar.xz
tar xf arm-gnu-toolchain-12.3.rel1-aarch64-none-elf.tar.xz
export PATH=$(pwd)/arm-gnu-toolchain-12.3.rel1-x86_64-aarch64-none-elf/bin:$PATH
```
{{% /tab %}}
{{% tab "macOS (ARM64)" %}}
```sh
wget 'https://developer.arm.com/-/media/Files/downloads/gnu/12.3.rel1/binrel/arm-gnu-toolchain-12.3.rel1-darwin-arm64-aarch64-none-elf.tar.xz?rev=cc2c1d03bcfe414f82b9d5b30d3a3d0d&hash=FBA1F3807EC2AA946B3170422669D15A' \
    -O arm-gnu-toolchain-12.3.rel1-aarch64-none-elf.tar.xz
tar xf arm-gnu-toolchain-12.3.rel1-aarch64-none-elf.tar.xz
export PATH=$(pwd)/arm-gnu-toolchain-12.3.rel1-darwin-arm64-aarch64-none-elf/bin:$PATH
```
{{% /tab %}}
{{% tab "macOS (x64)" %}}
```sh
wget 'https://developer.arm.com/-/media/Files/downloads/gnu/12.3.rel1/binrel/arm-gnu-toolchain-12.3.rel1-darwin-x86_64-aarch64-none-elf.tar.xz?rev=78193d7740294ebe8dbaa671bb5011b2&hash=1DF8812C4FFB7B78C589E702CFDE4471' \
    -O arm-gnu-toolchain-12.3.rel1-aarch64-none-elf.tar.xz
tar xf arm-gnu-toolchain-12.3.rel1-aarch64-none-elf.tar.xz
export PATH=$(pwd)/arm-gnu-toolchain-12.3.rel1-darwin-x86_64-aarch64-none-elf/bin:$PATH
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

```sh
cd examples/firewall
export MICROKIT_SDK=/path/to/sdk
# Platform to target
export MICROKIT_BOARD=imx8mp_evk
make
```

If you need to build a release version of the system, you must also specify:
```sh
make MICROKIT_CONFIG=release
```

Note that this will restrict serial output to components who have an explicit
sDDF serial subsystem connection. By default, this is only the webserver,
routers and ARP components.

## Firewall metaprogram

The firewall metaprogram is responsible for creating all the required Microkit
objects and sDDF connections. It also creates `.data` files containing
serialised encodings of this data for all the protection domains in the system.
We then `objcopy` these `.data` files into each `.elf` file, either in the
metaprogram itself or in the makefile `firewall.mk`.

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
addresses of the NICs. These will need to be updated to match your [testing
setup](../running).

## Next steps

If you have successfully compiled the system, there should be a file
`build/firewall.img`.

You can now move to [running the system](../running).
