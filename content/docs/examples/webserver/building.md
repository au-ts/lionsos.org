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

## Compiling the webserver system

For the web server to load the website's files, it expected to be
connected to an NFSv3 server. As part of the build process, you will
need to supply the IP address of this server.

{{% tabs "build" %}}
{{% tab "QEMU virt AArch64" %}}
```sh
cd examples/webserver
export MICROKIT_SDK=/path/to/sdk
# Platform to target
export MICROKIT_BOARD=qemu_virt_aarch64
# IP adddress of NFS server to connect to
export NFS_SERVER=<ip address of NFS server>
# NFS export to mount
export NFS_DIRECTORY=/path/to/dir
# Location of website's static files on NFS export
export WEBSITE_DIR=/path/to/website
# Compile the system
make
```
{{% /tab %}}
{{% tab "Odroid-C4" %}}
```sh
cd examples/webserver
export MICROKIT_SDK=/path/to/sdk
# Platform to target
export MICROKIT_BOARD=odroidc4
# IP adddress of NFS server to connect to
export NFS_SERVER=<ip address of NFS server>
# NFS export to mount
export NFS_DIRECTORY=/path/to/dir
# Location of website's static files on NFS export
export WEBSITE_DIR=/path/to/website
# Compile the system
make
```
{{% /tab %}}
{{% /tabs %}}

If you need to build a release version of the system:
```sh
make MICROKIT_CONFIG=release
```

## Next steps

If you have successfully compiled the system, there should be a file
`build/webserver.img`.

You can now move to [running the system on QEMU](../running_qemu) or
[running the system on hardware](../running_hardware).
