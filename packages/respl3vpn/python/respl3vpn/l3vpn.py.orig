# -*- mode: python; python-indent: 4 -*-
import ipaddress
import ncs
from ncs.application import Service
from ncs.dp import Action
import ipaddress
import traceback

class ServiceCallbacks(Service):
    """CFS L3VPN service

    This is the top level service for the CFS L3VPN service.
    """
    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        self.log.info('Service create(service=', service._path, ')')

        vrf_base_id = 10000
        vrf_id = vrf_base_id + service.id

        for ep in service.endpoint:
            nr = root.nodes.router[ep.router]
            vrf = nr.vrf.create(vrf_id)
            vrf.id = vrf_id
            vrf_interface = nr.vrf_interface.create(ep.interface)
            vrf_interface.vrf = vrf.name
            ipv4prefix = ipaddress.IPv4Network(ep.ipv4_prefix)
            if ipv4prefix.prefixlen == 31:
                er_ipv4_address = ipv4prefix.network_address
                cpe_ipv4_address = ipv4prefix.network_address + 1
            else:
                er_ipv4_address = ipv4prefix.network_address + 1
                cpe_ipv4_address = ipv4prefix.network_address + 2
            vrf_interface.ipv4_address = er_ipv4_address
            vrf_interface.ipv4_prefix_length = ipv4prefix.prefixlen

            if ep.ipv6_prefix:
                ipv6prefix = ipaddress.IPv6Network(ep.ipv6_prefix)
                if ipv6prefix.prefixlen == 127:
                    er_ipv6_address = ipv6prefix.network_address
                    cpe_ipv6_address = ipv6prefix.network_address + 1
                else:
                    er_ipv6_address = ipv6prefix.network_address + 1
                    cpe_ipv6_address = ipv6prefix.network_address + 2
                vrf_interface.ipv6_address = er_ipv6_address
                vrf_interface.ipv6_prefix_length = ipv6prefix.prefixlen

            vrf_interface.remote.device = ep.remote.device
            vrf_interface.remote.interface = ep.remote.interface

class FindServices(Action):
    @Action.action
    def cb_action(self, uinfo, name, kp, action_input, action_output, action_trans):
        with ncs.maapi.Maapi() as m:
            with ncs.maapi.Session(m, uinfo.username, 'l3vpn-find-services-action'):
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
        if service_type == 'l3vpn' or service_type == "all":
            self.find_l3vpn(root)

    # Find and create L3VPN services
    def find_l3vpn(self, root):
        for nr in root.nodes.router:
            for vrf in nr.vrf:
                l3vpn = root.rel3vpn__l3vpn.vpn.create(int(vrf.id) - 10000)
                for vrf_interface in nr.vrf_interface:
                    if vrf_interface.vrf == vrf.name:
                        ep = l3vpn.endpoint.create(nr.name, vrf_interface.name)
                        ipv4_network = ipaddress.ip_network(f'{vrf_interface.ipv4_address}/{vrf_interface.ipv4_prefix_length}', strict=False)
                        ep.ipv4_prefix = f'{ipv4_network.network_address}/{ipv4_network.prefixlen}'
                        ep.remote.device = vrf_interface.remote.device
                        ep.remote.interface = vrf_interface.remote.interface


    def find_vrf_ebgp_customer(self, root):
        for nr in root.nodes.router:
            for rfs_ebgp_neighbor in nr.ebgp_neighbor:
                vrf_ebgp_customer = root.rel3vpn__l3vpn.vrf_ebgp_customer.create(rfs_ebgp_neighbor.address)
                vrf_ebgp_customer.vpn_id = int(rfs_ebgp_neighbor.vrf) - 10000
                vrf_ebgp_customer.router = nr.name

class Main(ncs.application.Application):
    def setup(self):
        self.register_service('respvpn-l3vpn-servicepoint', ServiceCallbacks)
        self.register_action('l3vpn-find-services', FindServices)

    def teardown(self):
        pass
