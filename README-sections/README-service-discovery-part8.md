# Service Discovery - Part 8 - Find netinfra CFS Services

The details for each makefile target is found in [tutorial.mk](/tutorial.mk) 
file.

## Overview

Now all nodes / RFS have been found in the network and read in. Time to turn
to CFS layer. Since we have CFS services for network domain internal
infrastructure and one for L3VPN we have different find-services actions.

This will do discovery of netinfra CFS services. The service(s) will be fully 
discovered.

**25. Find netinfra services dry-run**

```
make tutorial-sd-25-find-services-netinfra-dry-run
```

Looking A-ok, let's do it

**26. Find netinfra services**

```
make tutorial-sd-26-find-services-netinfra
```
