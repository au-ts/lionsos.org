---
weight: 3
bookCollapseSection: true
title: "Language Support"
---

# Language Support

If you browse the LionsOS code and the various sub-projects that it uses such as libvmm and sDDF,
you will notice that everything is written in the C programming language.

One of the benefits of having isolated components is that, as long as the standard interfaces
across components are held, any number of programming languages can be used within a single
system.

For example, if you had a client that used the network sub-system, perhaps the client could be
in Rust while the virtualiser components are in C and the driver is some third language. As
long as the queue structures follow the same memory layout, everything will "just work".

At the moment, we do not have any examples of this kind of setup. The [Kitty reference system](/docs/kitty) is
all written in C code (with some MicroPython scripts).

## C

C will most likely remain as the the most common language of LionsOS components due to it being
amenable to formal verification and because our current verification tooling is intended for C.

### Standard Library (libc)

One of the considerations we need to make when using C is what standard library we want to use.
Unfortunately there is no standard C library that works across all operating systems unlike other
languages.

We do not necessarily *want* to use the full extent of a libc (in particular slow POSIX APIs such as
`read` and `write`) but understand that large or legacy clients cannot reasonably change to use
the asynchronous APIs that we mostly use.

Currently, we provide a libc for LionsOS systems based on a [fork](https://github.com/au-ts/musllibc/tree/lionsos) of
[musllibc](https://musl.libc.org/). For more information, please see the page on
[libc](/docs/use/language_support/libc) usage guidance.

## MicroPython

For ease of experimentation and certain client components, we make use of the
[MicroPython](https://github.com/micropython/micropython) interpreter to allow
Python scripts to run on LionsOS. MicroPython is a slimmed down version of
Python, intended for embedded use cases.

Our current support for MicroPython allows serial, networking, I<sup>2</sup>C, and
file system access. MicroPython can be used either as a REPL or as an interpeter for
a specific script upon boot.

It should be noted that not all Python programs will work with MicroPython out
of the box and there may be some porting necessary, see their
[website for details on compatibilty](https://docs.micropython.org/en/latest/genrst/index.html).

## Pancake

Pancake is a new programming language, developed at Trustworthy Systems in
co-ordination with other researchers, with the goal of creating verified
device drivers. It is a low-level systems langauge, with a similar syntax to C.

Pancake is not yet mature but is receiving internal use for writing
and formally verifying drivers.

You can find out more about the Pancake project
[here](https://trustworthy.systems/projects/pancake/).

## Rust

Rust is becoming popular within the embedded space and now with
[first-class Rust support for seL4](https://github.com/seL4/rust-sel4)
it is fairly easy to write Rust programs for an seL4 environment.

At this stage, we have only used Rust to write certain device drivers but
are interested in providing Rust bindings for LionsOS APIs in the future
as well as providing a port of the Rust standard library.

## WebAssembly (WASM)
LionsOS includes experimental support for running WebAssembly applications.
This is achieved by porting the
[wasm-micro-runtime](https://github.com/bytecodealliance/wasm-micro-runtime) to
LionsOS, allowing WASM modules to execute inside a LionsOS component.

Currently, our focus is on applications targeting
[WASI](https://github.com/WebAssembly/WASI), as WAMR provides a POSIX-based
implementation of WASI APIs. This makes WASM a useful driver for building out
LionsOS's libc and POSIX functionality. An example system demonstrates basic
file system and networking access from a WASM application running under WAMR.

Each WASM component in a LionsOS system links to its own copy of the runtime,
allowing the Microkit and system design to enforce isolation.

At present:
- Execution is limited to interpreter mode, but support for JIT and AOT
compilation is planned.
- Any WASM module can theoretically run, provided the required host functions
are provided and imported.
- Integration is highly experimental and primarily intended for research and
development.

Looking ahead, we aim to:
- Provide deeper LionsOS-native bindings for WASM components.
- Explore asynchronous interfaces as WASI evolves, enabling more efficient
interaction with LionsOS APIs.
