# Service Discovery - Part 1 - No Discrepancies

The details for each makefile target is found in [tutorial.mk](/tutorial.mk) 
file.

## Overview

This tutorial will show the discovery process step-by-step of one service 
residing in one device.

The service's configuration and implementation will be matching resulting in a 
successful service discovery without discrepances.

## Service Discovery Process - Step by Step

This will do service discovery on device CR-1. The service(s) will fully 
discovered and there is
no difference in the configurion on the device and the configuration in NSO.

**4. Save original configuration**

Save the original configuration from the device to a file (config/
original-CR-1.xml).
We will need this later in order to compare the original device configuration 
with the
output that our NSO services produces. We save it as the first step to avoid 
actions
like find-services (inadvertently) modifying the device configuration.

```
make tutorial-sd-4-save-original-device-config-cr-1
```

**5. Find services dry-run**

Run the find-services action in dry-run mode to see the output. It will crawl
the device configuration find the service instances and write them under
/nodes/router{X}/...
There should be NO changes to the configuration on the device itself. If there
are changes, the find-services code and potentially our NSO services need to
be updated. In this case, we know everything is going to go well.

```
make tutorial-sd-5-find-services-cr-1-dry-run
```

**6. Find services**

Run the find-services action to recreate the service input intent from device
config.

```
make tutorial-sd-6-find-services-cr-1
```

**7. Remove device configuration**

Now delete the configuration on the device in NSO. This is local ("commit
no-networking") and won't affect the actual device.

```
make tutorial-sd-7-delete-cr-1-device-config
```

**8. Re-deply service no-networking**

re-deploy the /nodes/router service for CR-1 to re-create the device config
based on NSO's service intent. Do this with no-networking as not to touch the
actual device. Now the configuration in /devices/device{CR-1}/config reflects
what our NSO services produce.

```
make tutorial-sd-8-redeploy-cr-1
```

**9. Save new configuration**

Save the configuration from /devices/device{CR-1}/config to an XML file 
(config/new-CR-1.xml").

```
make tutorial-sd-9-save-new-device-config-cr-1
```

**10. Compare configuration**

Compare the XML files, from what we orignally captured from the device with the
XML file of the output from the NSO services. The goal is for them to align to
100%. Anything that is missing (-) means our NSO services did not write enough
configuration and vice versa, if we see additions (+) then our NSO services
are writing more configuration that what was originally present on the device.

```
make tutorial-sd-10-diff-device-config-cr-1
```

**11. sync-from**

Return to being in-sync with the device, regardless if there were diffs or not.

```
make tutorial-sd-11-sync-from-cr-1
```