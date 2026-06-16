---
weight: 100
bookFlatSection: false
title: "Contributing"
---

# Contributing

All the LionsOS code is available on GitHub under an open-source
licence.

Key repositories are

 * The main LionsOS repository --- https://github.com/au-ts/lionsos
 * seL4 Device Driver Framework --- https://github.com/au-ts/sddf
 * libvmm (virtual machine monitor library) --- https://github.com/au-ts/libvmm
 * Documentation site (this website) --- https://github.com/au-ts/lionsos_docs

See the [repository ownership](#repository-ownership) section for details on
contacting the technical authority on each repository.

Currently, the main LionsOS repository has all the projects it depends on
(such as sDDF and libvmm) as Git submodules.

To contribute, first get the examples working.  Then generate pull
requests to the appropriate repository.

## General Guidelines

We use the same conventions as the seL4 microkernel which can be found here:
 *  [Style Guide](https://docs.sel4.systems/processes/style-guide.html)
 *  [Git Conventions](https://docs.sel4.systems/processes/git-conventions.html)
 *  [Code of Conduct](https://docs.sel4.systems/processes/conduct.html)
 *  [Pull requests](PullRequests)

Please read and abide by these --- especially the Code of Conduct.

## Areas of contribution

### Bugs and feature requests

If you have issues with building, running or using LionsOS please file
an issue on [GitHub](https://github.com/au-ts/lionsos) or see the
[getting help section](#getting-help).

GitHub is used to track bugs and features.

Please open bug and feature requests in the respective repository that fits
most with the issue. If you are not sure what repository is best, please
open an issue on the [LionsOS repository](https://github.com/au-ts/lionsos/issues).

### Documentation
If you try LionsOS and blog or vlog about it, please tell us via the
devel@sel4.systems email list.  Noteworthy blogs will be linked from
our site(s).

If you find issues (things that are documented wrong, missing
documentation, or are confusing) raise issues in the appropriate
repository, and/or generate pull requests to fix the issue.
That includes pull requests to the
[documentation](https://github.com/au-ts/lionsos_docs) repository.

### New device drivers and device virtualisers

All drivers and virtualisers are a part of the seL4 Device
Driver Framework and hence they should be contributed there.

When writing a new driver or virtualiser you will need to be
familiar with the general design of sDDF as well as the design of
the device class you are working with. This can be found in the
[design documentation](https://trustworthy.systems/projects/drivers/sddf-design-latest.pdf).

New drivers and virtualisers are welcomed.  These will generally be
contributed via pull requests to the
[sDDF](https://github.com/au-ts/sddf) repository.

Upstreaming a new *device class* is much more work as it involves a
signifcant amount of design, evaluation and experimentation. If you
wish to add a new device class to sDDF please [get in touch](#getting-help).

As drivers are not of much use on their own, please add in addition to
the driver, an example that uses it, and CI rules to test it, at least
to the 'it builds cleanly' stage.  The example can either be in the
LionsOS examples directory, or in the sDDF examples directory.

### Virtual machines

For creating and managing virtual machines in LionsOS we use libvmm. This
is a minimal library for allowing users to run a guest OS such as Linux
in a LionsOS system.

The main area contribution for libvmm is more virtIO devices (also known
as backends). The [virtIO specification](https://docs.oasis-open.org/virtio/virtio/v1.2/csd01/virtio-v1.2-csd01.html)
outlines a number of various device classes, some of which we have such as block
and network.

## Complete Systems
The intention is that (eventually) LionsOS systems can be built
entirely out-of-tree.  If you build an open-source LionsOS-based
system, please add a link to the documentation by submitting a PR to
the [LionsOS docs](https://github.com/au-ts/LionsOS_docs) repository.

## Getting Help
LionsOS was built and is supported by a small team at UNSW, Sydney.
We try to respond to queries on the devel@sel4.systems mailing list
(sign up [here](https://lists.sel4.systems/postorius/lists/devel.sel4.systems/)) and
via the [seL4
Mattermost](https://mattermost.trustworthy.systems/seL4-external) chat
server.

### Repository Ownership

Each Trustworthy Systems repository uses an **ownership system** for managing
code review. Repositories are split into component sections (sDDF device
classes, LionsOS examples etc.) and an owner is assigned to each. Additionally,
default owners of the entire repository are also assigned.

If you are working on a LionsOS example or feature, the owner of the most
closely related existing component will be your first port of call for code
review or technical advice. For new components or changes to miscellaneous parts
of LionsOS that do not have an obvious owner, select one of the default
reviewers. Your code will also be reviewed by this person - please assign them
as the reviewer when creating your PR.

The lists of owners of our repositories can be found here:
- [sDDF](https://github.com/au-ts/sddf/blob/main/MAINTAINERS.md)
- [LionsOS](https://github.com/au-ts/lionsos/blob/main/MAINTAINERS.md)
- [libVMM](https://github.com/au-ts/libvmm/blob/main/MAINTAINERS.md)
