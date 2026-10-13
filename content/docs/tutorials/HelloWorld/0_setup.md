---
weight: 1
bookFlatSection: false
title: "Setup"
---

# Part 0. Setup

To get you started, we have some introductory tutorial code for you to get started
with.

```sh
$ git clone https://github.com/au-ts/lionsos_tutorials
$ cd lionsos_tutorials
```

You should also clone LionsOS:

```sh
$ git clone https://github.com/au-ts/lionsos.git --branch {{< lionsos_version >}}
```

<!-- FIXME: Deduplicate this with every other page. I can't seem to find a good way to do this with Hugo.....  -->

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
nix develop github:au-ts/lionsos/{{< lionsos_version >}}
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

Now that you are setup, continue to [part 1](../1_provided).
