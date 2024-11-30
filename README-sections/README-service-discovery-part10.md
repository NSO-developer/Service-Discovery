# Service Discovery - Part 10 - Out of Band Changes

The details for each makefile target is found in [tutorial.mk](/tutorial.mk) 
file.

## Overview

This will do service discovery on device CR-3. The service(s) will fully 
discovered and there is
no difference in the configurion on the device and the configuration in NSO.

**29. Introduce some out-of-band changes in device ER-3**

Now some network guy adds more config to ER-3 manually by hand.

```
make tutorial-sd-29-oob-ebgp-customer
```

**30. Find services in device ER-3**

Another configuration coverage and diff check reveals there is a new
BGP neighbor configured on the device.

```
make tutorial-sd-30-find-services-er-3
```

This is a new case as we do not have an existing NSO service to modify nor to 
discover. We simply have no suitable service type in NSO to represent this
configuration in the network and so we must create a new service type.

**31. Add new service type and build**

Fortunately, a kind NSO service developer has prepared a new version 3 of our
packages that comes with a new service type as well as find-services support
for discovering it in device configuration. Let's apply version 3 and rebuild.

```
make tutorial-sd-31-apply-version-3-and-rebuild
```

**32. Find services in device ER-3 (including new service type)**

Use git diff to inspect the changes. Now let's do the config coverage and diff
check again.

```
make tutorial-sd-32-find-services-er-3
```

**33. Find l3vpn services dry-run**

And again for the CFS.

```
make tutorial-sd-33-find-services-l3vpn-dry-run
```

**34. Find l3vpn services**

and for L3VPN for realz

```
make tutorial-sd-34-find-services-l3vpn
```

Et voila! Back in sync again. We have now demonstrated the three main cases
for how a device can deviate from the configuration produced by NSO and how to
address those cases.