SHELL=/bin/bash

add-leftover-config-package:
	ln -sf ../../patches/leftover-config ../ncs-run/packages/

grab-diff-v2:
	diff -u <(git show HEAD:../packages/netinfra-rfs/python/netinfra_rfs/nodes_router.py) ../packages/netinfra-rfs/python/netinfra_rfs/nodes_router.py > v2/nodes_router.py.diff || true
	diff -u <(git show HEAD:../packages/netinfra-rfs/src/yang/netinfra-rfs-private.yang) ../packages/netinfra-rfs/src/yang/netinfra-rfs-private.yang > v2/netinfra-rfs-private.yang.diff || true
	diff -u <(git show HEAD:../packages/netinfra-rfs/templates/rfs-vrf-interface.xml) ../packages/netinfra-rfs/templates/rfs-vrf-interface.xml > v2/rfs-vrf-interface.diff || true
	diff -u <(git show HEAD:../packages/respl3vpn/python/respl3vpn/l3vpn.py) ../packages/respl3vpn/python/respl3vpn/l3vpn.py > v2/l3vpn.py.diff || true
	diff -u <(git show HEAD:../packages/respl3vpn/src/yang/respl3vpn.yang) ../packages/respl3vpn/src/yang/respl3vpn.yang > v2/respl3vpn.yang.diff || true

apply-patch-v2:
	patch ../packages/netinfra-rfs/python/netinfra_rfs/nodes_router.py < v2/nodes_router.py.diff
	patch ../packages/netinfra-rfs/src/yang/netinfra-rfs-private.yang < v2/netinfra-rfs-private.yang.diff
	patch ../packages/netinfra-rfs/templates/rfs-vrf-interface.xml < v2/rfs-vrf-interface.diff
	patch ../packages/respl3vpn/python/respl3vpn/l3vpn.py < v2/l3vpn.py.diff
	patch ../packages/respl3vpn/src/yang/respl3vpn.yang < v2/respl3vpn.yang.diff

grab-diff-v3:
	diff -u <(git show HEAD:../packages/netinfra-rfs/python/netinfra_rfs/nodes_router.py) ../packages/netinfra-rfs/python/netinfra_rfs/nodes_router.py > v3/nodes_router.py.diff || true
	diff -u <(git show HEAD:../packages/netinfra-rfs/src/yang/netinfra-rfs-private.yang) ../packages/netinfra-rfs/src/yang/netinfra-rfs-private.yang > v3/netinfra-rfs-private.yang.diff || true
	diff -u <(git show HEAD:../packages/respl3vpn/python/respl3vpn/l3vpn.py) ../packages/respl3vpn/python/respl3vpn/l3vpn.py > v3/l3vpn.py.diff || true
	diff -u <(git show HEAD:../packages/respl3vpn/src/yang/respl3vpn.yang) ../packages/respl3vpn/src/yang/respl3vpn.yang > v3/respl3vpn.yang.diff || true
	diff -u <(git show HEAD:../packages/netinfra-rfs/package-meta-data.xml) ../packages/netinfra-rfs/package-meta-data.xml > v3/rfs-package-meta-data.xml.diff || true
	diff -u <(git show HEAD:../packages/respl3vpn/package-meta-data.xml) ../packages/respl3vpn/package-meta-data.xml > v3/cfs-package-meta-data.xml.diff || true
	cp ../packages/netinfra-rfs/python/netinfra_rfs/ebgp_neighbor.py v3/rfs_ebgp_neighbor.py
	cp ../packages/netinfra-rfs/templates/rfs-ebgp-neighbor.xml v3/rfs-ebgp-neighbor.xml
	cp ../packages/respl3vpn/python/respl3vpn/vrf_ebgp_customer.py v3/vrf_ebgp_customer.py

apply-patch-v3:
	patch ../packages/netinfra-rfs/python/netinfra_rfs/nodes_router.py < v3/nodes_router.py.diff
	patch ../packages/netinfra-rfs/src/yang/netinfra-rfs-private.yang < v3/netinfra-rfs-private.yang.diff
	patch ../packages/respl3vpn/python/respl3vpn/l3vpn.py < v3/l3vpn.py.diff
	patch ../packages/respl3vpn/src/yang/respl3vpn.yang < v3/respl3vpn.yang.diff
	patch ../packages/netinfra-rfs/package-meta-data.xml < v3/rfs-package-meta-data.xml.diff
	patch ../packages/respl3vpn/package-meta-data.xml < v3/cfs-package-meta-data.xml.diff
	cp v3/rfs_ebgp_neighbor.py ../packages/netinfra-rfs/python/netinfra_rfs/ebgp_neighbor.py
	cp v3/rfs-ebgp-neighbor.xml ../packages/netinfra-rfs/templates/rfs-ebgp-neighbor.xml
	cp v3/vrf_ebgp_customer.py ../packages/respl3vpn/python/respl3vpn/vrf_ebgp_customer.py

restore-patches:
	git restore ../packages/netinfra-rfs/python/netinfra_rfs/nodes_router.py
	git restore ../packages/netinfra-rfs/src/yang/netinfra-rfs-private.yang
	git restore ../packages/netinfra-rfs/templates/rfs-vrf-interface.xml
	git restore ../packages/respl3vpn/python/respl3vpn/l3vpn.py
	git restore ../packages/respl3vpn/src/yang/respl3vpn.yang
	git restore ../packages/netinfra-rfs/package-meta-data.xml
	git restore ../packages/respl3vpn/package-meta-data.xml
	rm -f ../packages/netinfra-rfs/python/netinfra_rfs/ebgp_neighbor.py
	rm -f ../packages/netinfra-rfs/templates/rfs-ebgp-neighbor.xml
	rm -f ../packages/respl3vpn/python/respl3vpn/vrf_ebgp_customer.py

.PHONY: grab-diff-v2 apply-patch-v2 grab-diff-v3 apply-patch-v3 restore-patches