# Service Discovery - Part 3 - Ignoring Discrepancy

The details for each makefile target is found in [tutorial.mk](/tutorial.mk) 
file.

## Overview

This will do service discovery on device CR-2. The device will have discrepancy
that is chosen to be ignored. This is handled by creating a temporary service 
used for the discovery process only. This service will be created during the 
coverage check, to eliminate the diff between service coverage and the 
brownfield
config.

**14. Find services in device CR-2, round 2**

Now let's run the complete config coverage and diff check on CR-2 again. We
still see a diff. Looking at the diff, it contains configurations of a service
that we have not yet designed.

```
make tutorial-sd-14-conf-diff-check-cr-2
```

**15. Use a temporary service**

We want to continue the service discovery for now, and deal with that 
service later. This is done by adding those configurations to a dummy
service that covers the configurations, thus eliminating them from the diff.

```
make tutorial-sd-15-load-leftover-serivce
```

The package can be found in pathes/leftover-config

**16. Find services in device CR-2, round 3**

Run the complete config coverage and diff, once more, incorporating the 
leftover-configuration service. Now we should see no meaningful diff.

```
make tutorial-sd-16-conf-diff-check-cr-2
```
