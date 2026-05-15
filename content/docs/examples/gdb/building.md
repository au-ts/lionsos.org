+++
title = 'Building'
draft = false
weight = 10
+++

# Dependencies

Due to the pending PR's, you will need a separate version of Microkit, seL4 and
microkit_sdf_gen:

`Microkit` - https://github.com/au-ts/microkit/tree/child_vspace

`seL4` - https://github.com/au-ts/seL4/tree/libgdb

`microkit_sdf_gen` - https://github.com/au-ts/microkit_sdf_gen/tree/libgdb_child_pts


Please build the dependencies and appropriately setup your environment. The
provided repos contain the build instructions necessary

# Building

Once you have your dependencies, build as such:

```bash
export MICROKIT_SDK=<path_to_sdk>
export MICROKIT_BOARD=<board>
export MICROKIT_CONFIG=debug

make
```
