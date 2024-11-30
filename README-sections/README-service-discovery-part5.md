# Service Discovery - Part 5 - Configuration Discrepancy

The details for each makefile target is found in [tutorial.mk](/tutorial.mk) 
file.

## Overview

This will do service discovery on device ER-1. One service will have missing
configuration that will need to be handled.

**18. Find services on device ER-1**

Next up is ER-1 which does have a diff. eth3 has an mtu of 1600 which is
missing in the configuration produced by NSO. This is simply because the NSO
service does not set the MTU at all and rather relies on the device default of
1500.

```
make tutorial-sd-18-conf-diff-check-er-1
```

We need to address the difference in mtu between the original device
configuration and what NSO produces. We are now faced with the question
whether this is a mistake in the network or if it was intended. Fortunately we
have the network architect by our side that informs us that it is indeed
possible to configure different MTU on L3VPNs and so we know that the network
device is correct. 

**19. Fix the missing configuration**

We must add support in the NSO services to support configuring a variable MTU.
The network architect tells us that only two values are allowed, the default
of mtu 1500 or a higher mtu of 1600. Fortunately, a kind NSO service developer
has prepared a patch set that upgrades our services to version 2 which happens
to support a configurable MTU, both on the nodes/rfs layer as well as in the
CFS. The find-services code is also updated.

```
make tutorial-sd-19-jump-to-vpn-v2
```

**20. View differencies**

Let's look at the changes in version 2.

```
make tutorial-sd-20-git-diff-services
```

**21. Build service**

Build and reload our packages in NSO.

```
make tutorial-sd-21-rebuild
```
**22. Find services using updated service**

Now let's rerun the whole config coverage and diff check on ER-1 to see if we
properly read back the MTU.... and it does, yay!

```
make tutorial-sd-22-find-services-er-1
```

## NOTE
step22 will produce diff on /configuration/interfaces/interface{eth4}/mtu
because we added default value 1500 in vrf-interface service
this should be done in the cleanup phase after discovery.