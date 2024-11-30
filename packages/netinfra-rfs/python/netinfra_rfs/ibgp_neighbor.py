# -*- mode: python; python-indent: 4 -*-
import socket

import ncs
from ncs.application import Service
from ncs.dp import Action

class ServiceCallbacks(Service):
    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        self.log.info('Service create(service=', service._path, ')')

        vars = ncs.template.Variables()
        vars.add('DEVICE', service._parent._parent.name)
        vars.add('CR', 'true')

        # check if the address is IPv4 or IPv6
        afi = "IPV6"
        try:
            socket.inet_aton(service.address)
            afi = "IPV4"
        except socket.error:
            pass
        gname = f"{afi}-IBGP"
        if service.type == "full-mesh":
            gname += "-FULLMESH"
        elif service.type == "rr-client":
            gname += "-CLIENTS"
        service.vars.group_name = gname

        template = ncs.template.Template(service)
        template.apply('rfs-ibgp-neighbor', vars)


class Main(ncs.application.Application):
    def setup(self):
        self.register_service('netinfra-rfs-ibgp-neighbor-servicepoint', ServiceCallbacks)

    def teardown(self):
        pass
