# Service Design Concepts

This tutorial is based on a the idea to combine many useful design concepts 
and patterns to address many challenges from device onboarding to the 
transition to LSA.

NOTE! *The table is a summary of the concepts/patterns used and does not give 
a full explanation of the use-cases.*

| Pattern | Description |
| ------- | ----------- |
| Everything is a service | All configuration pushed to a device should be modelled as a service. Utilizes the CRUD functionality of NSO and the configuration gets an ownership. |
| One device per service (RFS) | Uniform design pattern suitable for both single node system and LSA setups. |
| Stacked services | CFS/RFS-layered services |
| Bundle device services | Services located per device (/nodes/router service). |

## Services

These are the implemented services and organized in the two tier stacked CFS/
RFS services.

```
CFS      netinfra/router (s)    netinfra/backbone-link (s)     infra-internal/ibgp-fullmesh (s)          
                            \__           |             ______/
                               \          |            / 
RFS                             nodes/router (l) 
                                    base-config (spc)
                                    ibgp-neighbor (spc)
                                    backbone-interface (s)
                                    internet-interface (s)
                                    vrf (s)
                                    vrf-interface (s)
```

s = service
l = list
spc = presence container service

| Service/Layer | Description |
| ------- | ----------- |
| CFS | The customer facing services |
| RFS | The resource facing services layer |
| /nodes/router | List enabling the one device per service concept. |


## SOmewhat REalistic Service PrOvider Network

https://gitlab.com/respnet/respnet