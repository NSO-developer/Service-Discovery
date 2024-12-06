# -*- mode: python; python-indent: 4 -*-
import ncs
from ncs.application import Service
from ncs.dp import Action

from resource_manager.id_allocator import id_request, id_read
from resource_manager.ipaddress_allocator import net_request, net_request_static, net_read

import ipaddress
import traceback

SERVICE_XPATH = "/netinfra/router[name='{name}']"
class ServiceCallbacks(Service):
    """CFS router service

    This is the top level service for creating a router in the network.
    """
    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        self.log.info('Service create(service=', service._path, ')')

        id_request(service=service,
                svc_xpath=SERVICE_XPATH.format(name=service.name),
                username=tctx.username,
                pool_name='router-id',
                allocation_name=service.name,
                sync_pool=False,
                requested_id=service.custom.id if service.custom.id else -1,
                sync_alloc=True,
                root=root)

        id = id_read(username=tctx.username,
                     root=root,
                     pool_name='router-id',
                     allocation_name=service.name)
        self.log.debug('Allocated ID: ', id)

        if service.custom.ipv4_address:
            net_request_static(service=service,
                    svc_xpath=SERVICE_XPATH.format(name=service.name),
                    username=tctx.username,
                    pool_name='ipv4-loopback',
                    allocation_name=service.name,
                    subnet_start_ip=service.custom.ipv4_address,
                    cidrmask=32,
                    sync_alloc=True,
                    root=root)
        else:
            net_request(service=service,
                        svc_xpath=SERVICE_XPATH.format(name=service.name),
                        username=tctx.username,
                        pool_name='ipv4-loopback',
                        allocation_name=service.name,
                        cidrmask=32,
                        sync_alloc=True,
                        root=root)

        ipv4_loopback = net_read(username=tctx.username,
                                 root=root,
                                 pool_name='ipv4-loopback',
                                 allocation_name = service.name).split('/')[0]

        ipv6_loopback = f'2001:db8::{id}'
        self.log.debug('IPv4 loopback: ', ipv4_loopback)
        self.log.debug('IPv6 loopback: ', ipv6_loopback)

        service.vars.id = id
        service.vars.ipv4_address = ipv4_loopback
        service.vars.ipv6_address = ipv6_loopback
        vars = ncs.template.Variables()
        vars.add('CR', 'true')
        template = ncs.template.Template(service)
        template.apply('router', vars)

        for role in service.role:
            if role.name == "core":
                ibgp_fm = root.infra_internal.ibgp_fullmesh.create()
                ibgp_fm_node = ibgp_fm.router.create(service.name)
                ibgp_fm_node.ipv4_address = ipv4_loopback
                ibgp_fm_node.ipv6_address = ipv6_loopback

class FindServices(Action):
    @Action.action
    def cb_action(self, uinfo, name, kp, action_input, action_output, action_trans):
        with ncs.maapi.Maapi() as m:
            with ncs.maapi.Session(m, uinfo.username, 'netinfra-find-services-action'):
                with m.start_write_trans() as trans:
                    try:
                        root = ncs.maagic.get_root(trans)
                        self.find_services(root, action_input.service_type)

                        params = ncs.maapi.CommitParams()
                        if action_input.dry_run.exists():
                            params.dry_run_cli()

                        if action_input.reconcile_type == 'keep-non-service-config':
                            params.reconcile_keep_non_service_config()
                        elif action_input.reconcile_type == 'discard-non-service-config':
                            params.reconcile_discard_non_service_config()
                        else:
                            raise Exception('No commit option option specified')

                        result = trans.apply_params(params=params)
                        action_output.success = True
                        action_output.message = 'ok'
                        if action_input.dry_run.exists() and 'local-node' in result:
                            action_output.cli.local_node.data = result['local-node']

                    except Exception as e:
                            self.log.error(f"{name} {kp}: action error {e}")
                            self.log.error(traceback.format_exc())
                            action_output.success = False
                            action_output.message = str(e)



    def find_services(self, root, service_type):
        if service_type == "router" or service_type == "all":
            self.find_routers(root)

        if service_type == "backbone-link" or service_type == "all":
            self.find_backbone_links(root)

    def find_routers(self, root):
        for router in root.nir__nodes.router:
            if root.netinfra__netinfra.router.exists(router.name):
                # We have to skip already found services, since RM does not let already allocated resource to be specified.
                continue

            netinfra_router = root.netinfra__netinfra.router.create(router.name)
            for role in router.base_config.role:
                netinfra_router.role.create(role.name)
            netinfra_router.custom.id = router.base_config.id
            netinfra_router.custom.ipv4_address = router.base_config.ipv4_address
            netinfra_router.custom.ipv6_address = router.base_config.ipv6_address
            self.log.info(f"Created router service for {router.name}")

    def find_backbone_links(self, root):
        for router in root.nir__nodes.router:
            for interface in router.backbone_interface:
                if router.name < interface.remote.device:
                    left_router = router.name
                    left_interface = interface.name
                    right_router = interface.remote.device
                    right_interface = interface.remote.interface
                    service = root.netinfra__netinfra.backbone_link.create(left_router, left_interface, right_router, right_interface)

                    ipv4_network = ipaddress.ip_network(f'{interface.ipv4_address}/{interface.ipv4_prefix_length}', strict=False)
                    service.custom.ipv4_prefix = f'{ipv4_network.network_address}/{ipv4_network.prefixlen}'

                    ipv6_network = ipaddress.ip_network(f'{interface.ipv6_address}/{interface.ipv6_prefix_length}', strict=False)
                    service.custom.ipv6_prefix =  f'{ipv6_network.network_address}/{ipv6_network.prefixlen}'

                    self.log.info(f"Created backbone link service for {left_router} {left_interface} <-> {right_router} {right_interface}")

class Main(ncs.application.Application):
    def setup(self):
        self.register_service('netinfra-router-servicepoint', ServiceCallbacks)
        self.register_action('netinfra-find-services', FindServices) #TODO: Move to a separate application component, since it handles all netinfra services?

    def teardown(self):
        pass
