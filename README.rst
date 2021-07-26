===============
docker-buildenv
===============

Tools for build environment on Docker.

You can build software on any Docker containers that include buildenv
(docker-buildenv), like::

  $ mkdir build
  $ cd build
  $ din anyakichi/yocto-builder
  builder@build:/build$ extract
  builder@build:/build$ setup
  builder@build:/build$ build

din is the script included in this repository.  You need to copy it
to a directory in PATH before using buildenv. ::

  $ curl -o ~/.local/bin/din \
      https://raw.githubusercontent.com/anyakichi/docker-buildenv/master/din.sh

extract, setup, and build are commands prepared by buildenv.

extract
    Download and extract source trees.

setup
    Setup build environment.

build
    Build software.

Normally, extract is required only once, so you can use the container
after the second::

  $ cd build
  $ din anyakichi/yocto-builder
  builder@build:/build$ setup
  builder@build:/build$ build


Developing and Building
=======================

docker-buildenv is just the environment for building, not editing.  We
normally open two terminal windows or tabs, one is for docker-buildenv
and the other is for the host environment, and we edit source files in
the host environment, then switch to docker-buildenv and build software
over and over.

Build environment for a specific software often requires a specific OS
version, which is old and inconvenient.  We can always use the latest
and customized version of a text editor and other development tools when
we develop with docker-buildenv.


Executable manual
=================

docker-buildenv is also for executable manual.  Development manuals
usually include processes like::

1. Install a specific OS to your machine.
2. Install some packages.
3. Download and extract a source tree.
4. Execute build commands.

docker-buildenv assumes that 1. and 2. are in Dockerfile, 3. is in
/etc/buildenv.d/extract.txt and 4. is in /etc/buildenv.d/build.txt.

The extract command just filter the lines starts with prompt ($) from
extract.txt and simply execute it.  So you can execute the manual if it
is put in the container.


Examples
========

* https://github.com/anyakichi/docker-yocto-builder
* https://github.com/anyakichi/docker-aosp-builder
