# -*- mode: python; python-indent: 4 -*-
import ncs
import re
from ncs.dp import Action

import traceback
class FindServices(Action):
    @Action.action
    def cb_action(self, uinfo, name, kp, action_input, action_output, action_trans):
            with ncs.maapi.Maapi() as m:
                with ncs.maapi.Session(m, uinfo.username, 'netinfra-nodes-find-services-action'):
                    with m.start_write_trans() as trans:
                        try:
                            root = ncs.maagic.get_root(trans)
                            service = root._get_node(kp)
                            self.find_services(root, service, action_input.service_type)

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

    def find_services(self, root, service, service_type):
            device = root.devices.device[service.name].config.junos__configuration

            if service_type == 'base-config' or service_type == 'all':
                self.find_base_config(device, service)

            if service_type == 'backbone-interface' or service_type == 'all':
                self.find_backbone_interfaces(device, service)

            if service_type == 'ibgp-neighbor' or service_type == 'all':
                self.find_ibgp_neighbor(device, service)

            if service_type == 'vrf' or service_type == 'all':
                self.find_vrf(device, service)

            if service_type == 'vrf-interface' or service_type == 'all':
                self.find_vrf_interface(device, service)

    def find_backbone_interfaces(self, device, service):
        backbone_if_services = dict()
        for iface in device.interfaces.interface:
            self.log.debug(f'Checking interface {iface.name}')
            if not iface.unit.exists(0):
                continue

            unit_0 = iface.unit[0]
            if not unit_0.description:
                continue
            
            self.log.info(f'Checking unit 0: {unit_0.description}')
            result = re.match(r'Link to ([^\s]+) \[([^\s]+)\]', unit_0.description)
            if not result:
                continue

            self.log.debug(f'Found backbone interface')
            remote_device = result.group(1)
            remote_interface = result.group(2)

            if not len(unit_0.family.inet.address) == 1:
                continue

            self.log.debug('Found ipv4')
            ipv4 = unit_0.family.inet.address.keys()[0]
            ipv4_address, ipv4_prefix_length = tuple(ipv4[0].split('/'))
            
            if not len(unit_0.family.inet6.address) == 1:
                continue

            self.log.debug('Found ipv6')
            ipv6 = unit_0.family.inet6.address.keys()[0]
            ipv6_address, ipv6_prefix_length = tuple(ipv6[0].split('/'))

            if not device.protocols.isis.interface.exists(iface.name):
                continue

            self.log.debug('Found isis')
            
            self.log.debug('Creating backbone interface service')
            bbif = service.backbone_interface.create(iface.name)
            bbif.disabled = iface.disable.exists()
            bbif.ipv4_address = ipv4_address
            bbif.ipv4_prefix_length = ipv4_prefix_length

            bbif.ipv6_address = ipv6_address
            bbif.ipv6_prefix_length = ipv6_prefix_length
            bbif.remote.device = remote_device
            bbif.remote.interface =  remote_interface

        return backbone_if_services

    def find_base_config(self, device, service):
        if not device.system.host_name:
            self.log.error('No hostname found')
            return

        hostname = device.system.host_name
        role = str()
        if hostname.startswith('CR'):
            role = 'core'
        elif hostname.startswith('ER'):
            role = 'edge'
        else:
            self.log.error(f'Cannot identify role through hostname {hostname}')
            return

        if not device.interfaces.interface.exists('lo0'):
            self.log.error('No lo0 interface found')
            return None

        if not device.interfaces.interface['lo0'].unit.exists('0'):
            self.log.error('No lo0.0 unit found')
            return

        family = device.interfaces.interface['lo0'].unit['0'].family
        if not len(family.inet.address) == 1:
            self.log.error('None, or more than 1 IPv4 address on lo0')
            return

        ipv4_address = family.inet.address.keys()[0][0].split('/')[0]

        if not len(family.inet6.address) == 1:
            self.log.error('None, or more than 1 IPv6 address on lo0')
            return

        ipv6_address = family.inet6.address.keys()[0][0].split('/')[0]

        self.log.debug('Configure base-config service')
        bc = service.base_config.create()
        bc.role.create(role)
        bc.id = ipv6_address.split(':')[-1]
        bc.ipv4_address = ipv4_address
        bc.ipv6_address = ipv6_address

    def find_ibgp_neighbor(self, device, service):
        for group in device.protocols.bgp.group:
            gname = group.name
            result = re.match(r'IPV[46]-(.*)', gname)
            if not result:
                self.log.debug(f'Skipping group {gname}')
                continue

            suffix = result.group(1)
            type = str()
            if suffix.endswith('IBGP'):
                type = 'direct'
            elif suffix.endswith('IBGP-FULLMESH'):
                type = 'full-mesh'
            elif suffix.endswith('IBGP-CLIENTS'):
                type = 'rr-client'

            self.log.debug('Configure ibgp-neighbor service')
            for neighbor in group.neighbor:
                service_neighbor = service.ibgp_neighbor.create(neighbor.name)
                service_neighbor.name = neighbor.description
                service_neighbor.type = type


    def find_vrf_interface(self, device, service):
        for iface in device.interfaces.interface:
            if 'Customer Access Interface' != iface.description:
                continue

            self.log.debug(f'Found VRF interface {iface.name}')
            if not iface.unit.exists(0):
                continue

            self.log.debug(f'Found unit 0')
            unit_0 = iface.unit[0]
            if not unit_0.description:
                continue

            self.log.info(f'Checking unit 0: {unit_0.description}')
            result = re.match(r'Customer VRF ([^\s]+) ([^\s]+) \[([^\s]+)\]', unit_0.description)
            if not result:
                continue

            self.log.debug('Looking for ipv4')
            if not len(unit_0.family.inet.address) == 1:
                continue

            ipv4 = unit_0.family.inet.address.keys()[0]
            ipv4_address, ipv4_prefix_length = tuple(ipv4[0].split('/'))

            self.log.debug('Create vrf interface service')
            vrf_if = service.vrf_interface.create(iface.name)
            vrf_if.vrf = result.group(1)
            vrf_if.ipv4_address = ipv4_address
            vrf_if.ipv4_prefix_length = ipv4_prefix_length
            vrf_if.remote.device = result.group(2)
            vrf_if.remote.interface = result.group(3)

    def find_vrf(self, device, service):
        for instance in device.routing_instances.instance:
            rd_type = instance.route_distinguisher.rd_type
            community = instance.vrf_target.community
            rid = rd_type.split(':')[-1]
            cid = community.split(':')[-1]
            if rid != cid:
                self.log.debug(f"RD-type and community id doesn't match. Skipping {instance.name}")
                continue

            self.log.debug('Create vrf service')
            service.vrf.create(instance.name).id = rid


class Main(ncs.application.Application):
    def setup(self):
        self.register_action('netinfra-nodes-find-services', FindServices)

    def teardown(self):
        pass
