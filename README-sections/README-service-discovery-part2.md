# Service Discovery - Part 2 - Minor Discrepancy

The details for each makefile target is found in [tutorial.mk](/tutorial.mk) 
file.

## Overview

This will do service discovery on device CR-2. The device will have one minor
discrepancy that will need to be handled.

**12. Find services in device CR-2**

Now we carry out that full procedure for the next router, CR-2, in one
convenient make target! Also note the extra sync-from at the end to make sure
we are in sync with the device again.

```
make tutorial-sd-12-conf-diff-check-cr-2
```

The output from the above find-services on cr-2 indicates we have a missing
service.

In the diff we can see lots of missing configuration around the eth3
interface.  Inspecting the device configuration we notice that the interface
description is incorrect. Instead of "Link to" it reads "Lonk to". Since the
find-services action is using the interface description as a "marker" to find
the service, it won't find the service if the description is incorrect.

In general, whenever there are differences between the network and what NSO
produces, in order to align them, we have the choice of correcting one or the
other. For a simple case like this, where the interface description contains
an obvious spelling mistake, the natural way to fix this is by correcting the
description. Since it is just a description, we know that changing it will not
have a service measurable impact in the network.

In contrast, changing firewall rules, routing protocol configuration or 
similar is likely to affect packet forwarding and will have a measurable 
impact, so even if it is incorrect, it is best to avoid changing it as part of 
finding services,  it is better to read in the network as-is by adding support 
in the service and find-services code for the "incorrect" device configuration 
and do a later cleanup round. One benefit of that is that once we have the 
services discovered and populated in NSO, we can use NSO automation to clean 
up the network.

Anyhow, let's fix the description.

**13. Correction**

Correct the interfaces description in the device.

```
make tutorial-sd-13-correct-interface-description
```
