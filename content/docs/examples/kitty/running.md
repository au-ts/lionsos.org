+++
title = 'Running'
date = 2023-12-12T21:00:47+11:00
draft = false
+++

# Running

The Kitty has several Mac-address endpoints, that need to be known by
several components.  It expects to be run while connected to a network
with a DHCP server that will hand out IPv4 addresses corresponding to
each of the Mac addresses.

As at the time of writing, the MAC addresses are:

| Component   |      MAC       |
|:------------|:--------------:|
| NFS         | 52:54:1:0:0:10 |
| MicroPython | 52:54:1:0:0:11 |

The Kitty needs an NFSv3 server, whose address is known at build
time.  Its MicroPython interpreter can import python modules from the
NFS filesystem.  The NFSv3 server has to be set up to export to
whatever IP address the NFS component is given by DHCP.

## Boot

When first booting up the system you will see the MicroPython REPL
prompt on the serial console:
```sh
MP|INFO: initialising!
MicroPython v1.22.2 on 2023-12-19; Odroid-C4 with Cortex A55
>>>
```

## Running the Kitty client

The Kitty client is responbile for drawing the user-interface
to the display as well as communicating with a server to send
any card IDs it processes.

Before running the Kitty client script, you must first start the
server. It is a fairly simple script that can be started with the
following commands:
```sh
# From the lionsos/examples/kitty directory
python3 server/server.py
```

You will need to supply the IP address of the machine that you are running the
server on to the Kitty program.

If you are running the Kitty example on QEMU, and running the server on your host
machine, then use the IP address `10.0.2.2`. This is the gateway IP address from QEMU
to your host machine.

If you have chosen to use a `deploy.py` script as outlined in the building section,
you will skip the following step.

Below is an example of running the Kitty example (without the deploy script):

```python
>>> import kitty

Welcome to Kitty!
Usage: kitty.run(String IP_ADDRESS).
        IP_ADDRESS: The IP address of the kitty server.
>>> kitty.run("10.0.2.2")
```

After executing the `kitty.run` command or the `deploy.py` script, you should see output on the display like so:
<img style="display: block; margin-left: auto; margin-right: auto" src="/kitty_display.png" alt="Picture of Kitty user interface" width="700"/>

## Using MicroPython

Upon boot, the system starts a MicroPython REPL that will allow you
to interact with various components connected to it.

Below are some examples of what you can do within the REPL.

<!-- ### Setting a timeout

```python
```
 -->
### Accessing the file system

Below is an example of accessing the file system mounted via NFS.

```python
>>> import os
>>> os.listdir()
[]
>>> with open('hello.py') as f:
...     f.write('print("hello world")\n')
... 
21
>>> os.listdir()
['hello.py']
>>> with open('hello.py') as f:
...     print(f.read())
... 
print("hello world")

>>> import hello
hello world
>>> os.remove('hello.py')
>>> os.listdir()
[]
```

<!-- ### Accessing the network

TODO -->
