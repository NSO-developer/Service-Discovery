# -*- mode: python; python-indent: 4 -*-
import ncs
from ncs.application import Service


class ServiceCallbacks(Service):

    @Service.create
    def cb_create(self, tctx, root, service, proplist):

        if service.name == 'CR-2':
            vars = ncs.template.Variables()
            template = ncs.template.Template(service)
            template.apply('cr-2-leftover', vars)

class Main(ncs.application.Application):
    def setup(self):
        self.log.info('Main RUNNING')
        self.register_service('leftover-config-servicepoint', ServiceCallbacks)
        
    def teardown(self):
        self.log.info('Main FINISHED')
