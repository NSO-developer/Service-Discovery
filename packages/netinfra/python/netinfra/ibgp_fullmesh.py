# -*- mode: python; python-indent: 4 -*-
import ncs
from ncs.application import Service

class ServiceCallbacks(Service):
    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        self.log.info('Service create(service=', service._path, ')')

        for router in service.router:
            vars = ncs.template.Variables()
            vars.add('DEVICE', router.name)
            template = ncs.template.Template(service)
            template.apply('cfs-ibgp-fullmesh', vars)

class Main(ncs.application.Application):
    def setup(self):
        self.register_service('netinfra-ibgp-fullmesh-servicepoint', ServiceCallbacks)

    def teardown(self):
        pass
