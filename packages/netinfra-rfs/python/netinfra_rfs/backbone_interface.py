# -*- mode: python; python-indent: 4 -*-
import ncs
from ncs.application import Service
from ncs.dp import Action

class SelfTest(Action):
    @Action.action
    def cb_action(self, uinfo, name, keypath, input, output):
        with ncs.maapi.single_read_trans('admin', 'python') as t:
            root = ncs.maagic.get_root(t)
            bbif_node = root._get_node(keypath)
            if_name = bbif_node.name
            self.log.info(f'Running self-test for {keypath}')
            service =  bbif_node._parent._parent

            adj_action = root.devices.device[service.name].rpc.rpc_get_isis_adjacency_information.get_isis_adjacency_information
            input = adj_action.get_input() # Do we want detailed info?
            result = adj_action.request(input)
            if not result.isis_adjacency_information.isis_adjacency.exists(if_name):
                output.success = False
                output.message = f'No adjacency for {if_name}'
                return
            
            if_adjacency = result.isis_adjacency_information.isis_adjacency[if_name]
            self.log.debug(f'Adjacency state: {if_adjacency.adjacency_state}')
            if 'Up' != if_adjacency.adjacency_state:
                output.success = False
                output.message = 'Adjacency not up'
                return
            
            self.log.debug(f'System name: {if_adjacency.system_name}')
            if if_adjacency.system_name != bbif_node.remote.device:
                output.success = False
                output.message = f'Expected {bbif_node.remote.device} but got {if_adjacency.system_name}'
                return
            
            output.success = True
            output.message = 'Service up'

class ServiceCallbacks(Service):
    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        self.log.info('Service create(service=', service._path, ')')

        vars = ncs.template.Variables()
        vars.add('DEVICE', service._parent._parent.name)
        vars.add('CR', 'true')
        service.vars.interface_name = service.name
        template = ncs.template.Template(service)
        template.apply('rfs-backbone-interface', vars)


class Main(ncs.application.Application):
    def setup(self):
        self.register_service('netinfra-rfs-backbone-interface-servicepoint', ServiceCallbacks)
        self.register_action('netinfra-rfs-backbone-interface-self-test', SelfTest)

    def teardown(self):
        pass
