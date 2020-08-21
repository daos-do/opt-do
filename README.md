# opt-do

DAOS-DO specific utilities installed in /opt/do

Copyright (C) 2020 Intel Corporation
All rights reserved.

This file is part of the DAOS Project. It is subject to the license terms
in the LICENSE file found in the top-level directory of this distribution
and at https://img.shields.io/badge/License-Apache%202.0-blue.svg.
No part of the DAOS Project, including this file, may be copied, modified,
propagated, or distributed except according to the terms contained in the
LICENSE file.


Install as follows, Use python2 for Ubuntu 14.04 instead of python3

~~~ bash
tar -C / -xf opt_do_python_0.0.0.tar.gz
ln -s /opt/do/python3 /opt/do/python
~~~

Usage:

Molecule needs the install directory pre-pended to PATH.

~~~ bash
PATH="/opt/do/python/bin:$PATH"
ansible --version
ansible 2.9.0
  config file = None
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /opt/do/python/lib/python3.8/site-packages/ansible
  executable location = /opt/do/python/bin/ansible
  python version = 3.8.0 (default, Nov  4 2019, 17:44:23) [GCC 8.3.1 20190223 (Red Hat 8.3.1-2)]
~~~

## Maintenance

When making changes, update the opt_do_version.txt file to set a new version
for OPT_DO_VERSION.

The version of Python 3 and Packer are also specified in the opt_do_version.txt
file.

The versions of the python modules are specified in the opt_do_requirements.txt
file.
