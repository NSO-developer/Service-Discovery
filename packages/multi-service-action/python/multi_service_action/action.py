import ncs
from ncs.dp import Action
import asyncio
from maagic_copy.maagic_copy import maagic_copy


class InvokeAction(Action):
    
    @Action.action
    def cb_action(self, uinfo, name, kp, input, output, trans):
        asyncio.run(self.run_action(uinfo, name, kp, input, output, trans))
        
    async def run_action(self, uinfo, name, kp, input, output, trans):
        self.log.info(f'Running action: {kp}, {name}')
        action_name = name.replace('-', '_')
        
        threads = list()
        with ncs.maapi.single_write_trans('admin', 'system') as t:
            root = ncs.maagic.get_root(t)
            this_node = root._get_node(kp)
            for node_name in this_node:
                node = getattr(this_node, node_name.split(':')[1].replace('-', '_'))
                
                if isinstance(node, ncs.maagic.PresenceContainer):
                    self.log.info(f'Container service: {node._path}')
                    threads.append(asyncio.to_thread(self.request_action, input, node._path, action_name))
                        
                elif isinstance(node, ncs.maagic.List):
                    services = input.services if hasattr(input, 'services') and input.services.exists() else None
                    if services:
                        for service in services:
                            self.log.info('service=', service)
                            self.log.info(f'List service: {node[service]._path}')
                            threads.append(asyncio.to_thread(self.request_action, input, node[service]._path, action_name))
                    else:
                        for service_node in node:
                            self.log.info(f'Regular service: {service_node._path}')
                            threads.append(asyncio.to_thread(self.request_action, input, service_node._path, action_name))

        result = await asyncio.gather(*threads)
        for service_path, action_result in result:
            service_output = output.service.create(service_path)
            maagic_copy(action_result, service_output)
    
    def request_action(self, input, node_path, action_name):
        self.log.info(f'Requesting action: {node_path}, {action_name}')
        with ncs.maapi.single_write_trans('admin', 'system') as t:
            root = ncs.maagic.get_root(t)
            node = root._get_node(node_path)
            if action_name in dir(node): # Possible to do this befiore we start a trans?
                self.log.info(f'Running action: {action_name}')
                action = getattr(node, action_name)
                action_params = action.get_input()
                maagic_copy(input, action_params)
                return node_path, action.request(action_params)