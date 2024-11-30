# -*- mode: python; python-indent: 4 -*-
import ncs
from ncs.application import Service

class ServiceCallbacks(Service):
    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        self.log.info('Service create(service=', service._path, ')')
        
        vars = ncs.template.Variables()
        vars.add('DEVICE', service._parent._parent.name)
        
        if service.type == 'customer':
            service.vars.group_name = 'IPV4-VPN-CUSTOMER'
            service.vars.description = 'Customer router'
        else:
            raise Exception('No type specified')

        template = ncs.template.Template(service)
        template.apply('rfs-ebgp-neighbor', vars)


class Main(ncs.application.Application):
    def setup(self):
        self.register_service('netinfra-rfs-ebgp-neighbor-servicepoint', ServiceCallbacks)

    def teardown(self):
        pass
