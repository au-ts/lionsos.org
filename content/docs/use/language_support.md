---
weight: 3
bookFlatSection: false
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

Our [current plan](https://github.com/au-ts/lionsos/issues/48) is to create a libc for LionsOS-based
system using the [picolibc](https://github.com/picolibc/picolibc) project.

## Pancake

Pancake is a new programming language, developed at Trustworthy Systems in
co-ordination with other researchers, with the goal of creating verified
device drivers.

Pancake, is not mature yet but is receiving internal use for writing
drivers.

You can find out more about the Pancake project [here](https://trustworthy.systems/projects/pancake/).

## Rust

Rust is becoming popular within the embedded space and with the recent [first-class Rust support for seL4](https://github.com/seL4/rust-sel4)
we have started to experiment with Rust but do not yet have any
components written in Rust. This is something on our roadmap though.
