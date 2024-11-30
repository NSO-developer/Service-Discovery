# -*- mode: python; python-indent: 4 -*-
import ncs
from ncs.application import Service
from ncs.dp import Action

class ServiceCallbacks(Service):
    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        self.log.info('Service create(service=', service._path, ')')

        vars = ncs.template.Variables()
        vars.add('CR', 'true')
        service.vars.asn = 64999 # TODO: don't hard-code but read from where?
        service.vars.router_id = '123.123.123.123'
        template = ncs.template.Template(service)
        template.apply('rfs-vrf', vars)


class Main(ncs.application.Application):
    def setup(self):
        self.register_service('netinfra-rfs-vrf-servicepoint', ServiceCallbacks)

    def teardown(self):
        pass
