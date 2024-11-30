# -*- mode: python; python-indent: 4 -*-
import ncs
from ncs.application import Service


# ------------------------
# SERVICE CALLBACK EXAMPLE
# ------------------------
class ServiceCallbacks(Service):
    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        self.log.info('Service create(service=', service._path, ')')


        # calculate the isis-sid and nsap-address from IPv4 address
        # first split the address into an array of padded strings
        # 123.45.67.8 => ['123', '045', '067', '008'],
        # then join to form a long string '123045067008'
        # and split the long string into '1230.4506.7008' to be used in the final nsap_address
        padded_split = [ f'{int(v):03d}' for v in service.ipv4_address.split('.')]
        join_str = ''.join(padded_split)
        service.vars.isis_net = f'49.0001.{join_str[0:4]}.{join_str[4:8]}.{join_str[8:]}.00'

        service.vars.asn = 64999
        service.vars.router_id = service.ipv4_address

        vars = ncs.template.Variables()
        vars.add('DEVICE', service._parent.name)

        template = ncs.template.Template(service)
        template.apply('base-config', vars)


class Main(ncs.application.Application):
    def setup(self):
        self.register_service('netinfra-rfs-base-config-servicepoint', ServiceCallbacks)

    def teardown(self):
        pass
