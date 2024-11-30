# -*- mode: python; python-indent: 4 -*-
import ncs
from ncs.application import Service

class ServiceCallbacks(Service):
    """CFS VRF eBGP Customer service

    This is the top level service for the VRF eBGP Customer service.
    """
    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        self.log.info('Service create(service=', service._path, ')')

        vrf_base_id = 10000
        vrf_id = vrf_base_id + service.vpn_id

        ebgp_neighbor_rfs = root.nodes.router[service.router].ebgp_neighbor.create(service.address)
        ebgp_neighbor_rfs.type = 'customer'
        ebgp_neighbor_rfs.vrf = vrf_id

class Main(ncs.application.Application):
    def setup(self):
        self.register_service('respvpn-vrf-ebgp-customer-servicepoint', ServiceCallbacks)

    def teardown(self):
        pass
