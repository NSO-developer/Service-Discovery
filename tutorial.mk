# Service Discovery tutorial

# Load them with initial configuration required for this tutorial. NSO requires
# resource pools, for the resource manager. The netsim devices are loaded with
# the brownfield config.
tutorial-sd-1-start:
	$(MAKE) configure configure-resource-pools
	$(MAKE) netsim-load-xml-conf NETSIM=CR-1 FILE=device-configs-brownfield/CR-1.xml
	$(MAKE) netsim-load-xml-conf NETSIM=CR-2 FILE=device-configs-brownfield/CR-2.xml
	$(MAKE) netsim-load-xml-conf NETSIM=CR-3 FILE=device-configs-brownfield/CR-3.xml
	$(MAKE) netsim-load-xml-conf NETSIM=ER-1 FILE=device-configs-brownfield/ER-1.xml
	$(MAKE) netsim-load-xml-conf NETSIM=ER-2 FILE=device-configs-brownfield/ER-2.xml
	$(MAKE) netsim-load-xml-conf NETSIM=ER-3 FILE=device-configs-brownfield/ER-3.xml

# Load up config for our brownfield network
tutorial-sd-2-onboard-devices:
	@$(MAKE) loadconf FILE=netsim_init.xml
	@$(MAKE) runcmdJ CMD="request devices sync-from"

# Create /nodes/router services in NSO, these are just a minimal skeleton,
# essentially the bare minimum for the node service, so that we in turn get 
# a /devices/device{foo} The find-services actions themselves are located under 
# /nodes/router so that's why we need the /nodes/router service instances.
tutorial-sd-3-create-nodes:
	@$(MAKE) loadconf FILE=nso-config/config-nodes.xml

# Save the original configuration from the device to a file. We will need this
# later in order to compare the original device configuration with the output
# that our NSO services produces. We save it as the first step to avoid actions
# like find-services (inadvertently) modifying the device configuration.
tutorial-sd-4-save-original-device-config-cr-1:
	@$(MAKE) runcmdJ CMD="show configuration devices device CR-1 config | display xml | save config/original-CR-1.xml"

# Run the find-services action in dry-run mode to see the output. It will crawl
# the device configuration find the service instances and write them under
# /nodes/router{X}/...
# There should be NO changes to the configuration on the device itself. If there
# are changes, the find-services code and potentially our NSO services need to
# be updated. In this case, we know everything is going to go well.
tutorial-sd-5-find-services-cr-1-dry-run:
	@$(MAKE) runcmdJ CMD="request nodes router CR-1 find-services dry-run"

# Run the find-services action to recreate the service input intent from device
# config.
tutorial-sd-6-find-services-cr-1:
	@$(MAKE) runcmdJ CMD="request nodes router CR-1 find-services"

# Now delete the configuration on the device in NSO. This is local ("commit
# no-networking") and won't affect the actual device.
tutorial-sd-7-delete-cr-1-device-config:
	@$(MAKE) runcmdJ CMD="request devices device CR-1 delete-config"

# re-deploy the /nodes/router service for CR-1 to re-create the device config
# based on NSO's service intent. Do this with no-networking as not to touch the
# actual device. Now the configuration in /devices/device{CR-1}/config reflects
# what our NSO services produce.
tutorial-sd-8-redeploy-cr-1:
	@$(MAKE) runcmdJ CMD="request nodes router CR-1 re-deploy no-networking"

# Save the configuration from /devices/device{CR-1}/config to an XML file.
tutorial-sd-9-save-new-device-config-cr-1:
	@$(MAKE) runcmdJ CMD="show configuration devices device CR-1 config | display xml | save config/new-CR-1.xml"

# diff the XML files, from what we orignally captured from the device with the
# XML file of the output from the NSO services. The goal is for them to align to
# 100%. Anything that is missing (-) means our NSO services did not write enough
# configuration and vice versa, if we see additions (+) then our NSO services
# are writing more configuration that what was originally present on the device.
tutorial-sd-10-diff-device-config-cr-1:
	diff -u config/original-CR-1.xml config/new-CR-1.xml

# Return to being in-sync with the device, regardless if there were diffs or not
tutorial-sd-11-sync-from-cr-1:
	@$(MAKE) runcmdJ CMD="request devices device CR-1 sync-from"

# The above procedure is what we refer to as the "configuration coverage and
# diff check", which consists of the following steps:
# - device sync-from
# - save original device config
# - run find-services action to create NSO service instances
# - delete local device config
# - re-deploy NSO service instance no-networking to produce device config
# - save new device config
# - compare original with new device config
# - no differences? all good!
#   - now we can also correctly do a reconcile to take ownership of all config
#     on the device
#   - some differences? iterate on the service design to reduce diffs
#
# Now we carry out that full procedure for the next router, CR-2, in one
# convenient make target! Also note the extra sync-from at the end to make sure
# we are in sync with the device again.
tutorial-sd-12-conf-diff-check-cr-2:
	@$(MAKE) runcmdJ CMD="request devices device CR-2 sync-from"
	@$(MAKE) runcmdJ CMD="show configuration devices device CR-2 config | display xml | save config/original-CR-2.xml"
	@$(MAKE) runcmdJ CMD="request nodes router CR-2 find-services"
	@$(MAKE) runcmdJ CMD="request devices device CR-2 delete-config"
	@$(MAKE) runcmdJ CMD="request nodes router CR-2 re-deploy no-networking"
	@$(MAKE) runcmdJ CMD="show configuration devices device CR-2 config | display xml | save config/new-CR-2.xml"
	diff -u config/original-CR-2.xml config/new-CR-2.xml || true
	@$(MAKE) runcmdJ CMD="request devices device CR-2 sync-from"

# The output from the above find-services on cr-2 indicates we have a missing
# service. In the diff we can see lots of missing configuration around the eth3
# interface.  Inspecting the device configuration we notice that the interface
# description is incorrect. Instead of "Link to" it reads "Lonk to". Since the
# find-services action is using the interface description as a "marker" to find
# the service, it won't find the service if the description is incorrect. In
# general, whenever there are differences between the network and what NSO
# produces, in order to align them, we have the choice of correcting one or the
# other. For a simple case like this, where the interface description contains
# an obvious spelling mistake, the natural way to fix this is by correcting the
# description. Since it is just a description, we know that changing it will not
# have a service measurable impact in the network. In contrast, changing
# firewall rules, routing protocol configuration or similar is likely to affect
# packet forwarding and will have a measurable impact, so even if it is
# incorrect, it is best to avoid changing it as part of finding services, it is
# better to read in the network as-is by adding support in the service and
# find-services code for the "incorrect" device configuration and do a later
# cleanup round. One benefit of that is that once we have the services
# discovered and populated in NSO, we can use NSO automation to clean up the
# network. Anyhow, let's fix the description.
tutorial-sd-13-correct-interface-description:
	@$(MAKE) runcmdJ CMD='configure\nset devices device CR-2 config configuration interfaces interface eth3 unit 0 description \"Link to ER-1 [eth2]\"\ncommit\nexit'

# Now let's run the complete config coverage and diff check on CR-2 again. We
# still see a diff. Looking at the diff, it contains configurations of a service
# that we have not yet designed.
tutorial-sd-14-conf-diff-check-cr-2:
	@$(MAKE) runcmdJ CMD="request devices device CR-2 sync-from"
	@$(MAKE) runcmdJ CMD="request nodes router CR-2 find-services"
	@$(MAKE) runcmdJ CMD="show configuration devices device CR-2 config | display xml | save config/original-CR-2.xml"
	@$(MAKE) runcmdJ CMD="request devices device CR-2 delete-config"
	@$(MAKE) runcmdJ CMD="request nodes router CR-2 re-deploy no-networking"
	@$(MAKE) runcmdJ CMD="show configuration devices device CR-2 config | display xml | save config/new-CR-2.xml"
	diff -u config/original-CR-2.xml config/new-CR-2.xml || true
	@$(MAKE) runcmdJ CMD="request devices device CR-2 sync-from"

# We want to continue the service discovery for now, and deal with that
# service later. This is done by adding those configurations to a dummy
# service that covers the configurations, thus eliminating them from the diff.
tutorial-sd-15-load-leftover-serivce:
	$(MAKE) -C patches add-leftover-config-package
	$(MAKE) rebuild

# Run the complete config coverage and diff, once more, incorporating the
# leftover-configuration service. Now we should see no meaningful diff.
tutorial-sd-16-conf-diff-check-cr-2:
	@$(MAKE) runcmdJ CMD="request devices device CR-2 sync-from"
	@$(MAKE) runcmdJ CMD="request nodes router CR-2 find-services"
	@$(MAKE) runcmdJ CMD="configure \n set leftover-config CR-2 \n commit"
	@$(MAKE) runcmdJ CMD="show configuration devices device CR-2 config | display xml | save config/original-CR-2.xml"
	@$(MAKE) runcmdJ CMD="request devices device CR-2 delete-config"
	@$(MAKE) runcmdJ CMD="request nodes router CR-2 re-deploy no-networking"
	@$(MAKE) runcmdJ CMD="request leftover-config CR-2 re-deploy no-networking"
	@$(MAKE) runcmdJ CMD="show configuration devices device CR-2 config | display xml | save config/new-CR-2.xml"
	diff -u config/original-CR-2.xml config/new-CR-2.xml || true
	@$(MAKE) runcmdJ CMD="request devices device CR-2 sync-from"

# Proceed with CR-3, which again has no diff.
tutorial-sd-17-conf-diff-check-cr-3:
	@$(MAKE) runcmdJ CMD="request devices device CR-3 sync-from"
	@$(MAKE) runcmdJ CMD="request nodes router CR-3 find-services"
	@$(MAKE) runcmdJ CMD="show configuration devices device CR-3 config | display xml | save config/original-CR-3.xml"
	@$(MAKE) runcmdJ CMD="request devices device CR-3 delete-config"
	@$(MAKE) runcmdJ CMD="request nodes router CR-3 re-deploy no-networking"
	@$(MAKE) runcmdJ CMD="show configuration devices device CR-3 config | display xml | save config/new-CR-3.xml"
	diff -u config/original-CR-3.xml config/new-CR-3.xml || true
	@$(MAKE) runcmdJ CMD="request devices device CR-3 sync-from"

# Next up is ER-1 which does have a diff. eth3 has an mtu of 1600 which is
# missing in the configuration produced by NSO. This is simply because the NSO
# service does not set the MTU at all and rather relies on the device default of
# 1500.
tutorial-sd-18-conf-diff-check-er-1:
	@$(MAKE) runcmdJ CMD="request devices device ER-1 sync-from"
	@$(MAKE) runcmdJ CMD="request nodes router ER-1 find-services"
	@$(MAKE) runcmdJ CMD="show configuration devices device ER-1 config | display xml | save config/original-ER-1.xml"
	@$(MAKE) runcmdJ CMD="request devices device ER-1 delete-config"
	@$(MAKE) runcmdJ CMD="request nodes router ER-1 re-deploy no-networking"
	@$(MAKE) runcmdJ CMD="show configuration devices device ER-1 config | display xml | save config/new-ER-1.xml"
	diff -u config/original-ER-1.xml config/new-ER-1.xml || true
	@$(MAKE) runcmdJ CMD="request devices device ER-1 sync-from"

# We need to address the difference in mtu between the original device
# configuration and what NSO produces. We are now faced with the question
# whether this is a mistake in the network or if it was intended. Fortunately we
# have the network architect by our side that informs us that it is indeed
# possible to configure different MTU on L3VPNs and so we know that the network
# device is correct. We must add support in the NSO services to support
# configuring a variable MTU. The network architect tells us that only two
# values are allowed, the default of mtu 1500 or a higher mtu of 1600.
# Fortunately, a kind NSO service developer has prepared a patch set that
# upgrades our services to version 2 which happens to support a configurable
# MTU, both on the nodes/rfs layer as well as in the CFS. The find-services code
# is also updated.
tutorial-sd-19-jump-to-vpn-v2:
	$(MAKE) -C patches apply-patch-v2

# Let's look at the changes in version 2:
tutorial-sd-20-git-diff-services:
	git diff packages

# Build and reload our packages in NSO
tutorial-sd-21-rebuild:
	$(MAKE) rebuild

# Now let's rerun the whole config coverage and diff check on ER-1 to see if we
# properly read back the MTU.... and it does, yay!
# Note that there is a diff showing us that our disovered services will set the 
# mtu to 1500 on eth4.
# Since this is the default value, the diff can be ignored. Or even better 
# explicitly configured on the 
# device manually, to remove it from the diff. We will simply ignore it for now.
tutorial-sd-22-find-services-er-1:
	@$(MAKE) runcmdJ CMD="request devices device ER-1 sync-from"
	@$(MAKE) runcmdJ CMD="request nodes router ER-1 find-services"
	rm config/original-ER-1.xml
	@$(MAKE) runcmdJ CMD="show configuration devices device ER-1 config | display xml | save config/original-ER-1.xml"
	@$(MAKE) runcmdJ CMD="request devices device ER-1 delete-config"
	@$(MAKE) runcmdJ CMD="request nodes router ER-1 re-deploy no-networking"
	rm config/new-ER-1.xml
	@$(MAKE) runcmdJ CMD="show configuration devices device ER-1 config | display xml | save config/new-ER-1.xml"
	diff -u config/original-ER-1.xml config/new-ER-1.xml || true
	@$(MAKE) runcmdJ CMD="request devices device ER-1 sync-from"

# Let's do the same thing for ER-2
tutorial-sd-23-find-services-er-2:
	@$(MAKE) runcmdJ CMD="request devices device ER-2 sync-from"
	@$(MAKE) runcmdJ CMD="request nodes router ER-2 find-services"
	@$(MAKE) runcmdJ CMD="show configuration devices device ER-2 config | display xml | save config/original-ER-2.xml"
	@$(MAKE) runcmdJ CMD="request devices device ER-2 delete-config"
	@$(MAKE) runcmdJ CMD="request nodes router ER-2 re-deploy no-networking"
	@$(MAKE) runcmdJ CMD="show configuration devices device ER-2 config | display xml | save config/new-ER-2.xml"
	diff -u config/original-ER-2.xml config/new-ER-2.xml || true
	@$(MAKE) runcmdJ CMD="request devices device ER-2 sync-from"

# ... and ER-3
tutorial-sd-24-find-services-er-3:
	@$(MAKE) runcmdJ CMD="request nodes router ER-3 find-services"
	@$(MAKE) runcmdJ CMD="request devices device ER-3 sync-from"
	@$(MAKE) runcmdJ CMD="show configuration devices device ER-3 config | display xml | save config/original-ER-3.xml"
	@$(MAKE) runcmdJ CMD="request devices device ER-3 delete-config"
	@$(MAKE) runcmdJ CMD="request nodes router ER-3 re-deploy no-networking"
	@$(MAKE) runcmdJ CMD="show configuration devices device ER-3 config | display xml | save config/new-ER-3.xml"
	diff -u config/original-ER-3.xml config/new-ER-3.xml || true
	@@$(MAKE) runcmdJ CMD="request devices device ER-3 sync-from"

# Now all nodes / RFS have been found in the network and read in. Time to turn
# to CFS layer. Since we have CFS services for network domain internal
# infrastructure and one for L3VPN we have different find-services actions.
# Let's check out the dry-run for netinfra first
tutorial-sd-25-find-services-netinfra-dry-run:
	@$(MAKE) runcmdJ CMD="request netinfra find-services dry-run"

# looking A-ok, let's do it
tutorial-sd-26-find-services-netinfra:
	@$(MAKE) runcmdJ CMD="request netinfra find-services"

# and for L3VPN
tutorial-sd-27-find-services-l3vpn-dry-run:
	@$(MAKE) runcmdJ CMD="request l3vpn find-services dry-run"

# and for L3VPN for realz
tutorial-sd-28-find-services-l3vpn:
	@$(MAKE) runcmdJ CMD="request l3vpn find-services"

# Now some network guy adds more config to ER-3 manually by hand.
tutorial-sd-29-oob-ebgp-customer:
	@$(MAKE) loadconf FILE=nso-config/config-oob-vrf-ebgp-customer.xml

# Another configuration coverage and diff check reveals there is a new
# BGP neighbor configured on the device. This is a new case as we do not have an
# existing NSO service to modify nor to discover. We simply have no suitable
# service type in NSO to represent this configuration in the network and so we
# must create a new service type.
tutorial-sd-30-find-services-er-3:
	@$(MAKE) runcmdJ CMD="request devices device ER-3 sync-from"
	@$(MAKE) runcmdJ CMD="request nodes router ER-3 find-services"
	@$(MAKE) runcmdJ CMD="show configuration devices device ER-3 config | display xml | save config/original-ER-3.xml"
	@$(MAKE) runcmdJ CMD="request devices device ER-3 delete-config"
	@$(MAKE) runcmdJ CMD="request nodes router ER-3 re-deploy no-networking"
	@$(MAKE) runcmdJ CMD="show configuration devices device ER-3 config | display xml | save config/new-ER-3.xml"
	diff -u config/original-ER-3.xml config/new-ER-3.xml || true
	@$(MAKE) runcmdJ CMD="request devices device ER-3 sync-from"

# Fortunately, a kind NSO service developer has prepared a new version 3 of our
# packages that comes with a new service type as well as find-services support
# for discovering it in device configuration. Let's apply version 3 and rebuild.
tutorial-sd-31-apply-version-3-and-rebuild:
	$(MAKE) -C patches apply-patch-v3
	$(MAKE) rebuild

# Use git diff to inspect the changes. Now let's do the config coverage and diff
# check again:
tutorial-sd-32-find-services-er-3:
	@$(MAKE) runcmdJ CMD="request devices device ER-3 sync-from"
	@$(MAKE) runcmdJ CMD="request nodes router ER-3 find-services"
	@$(MAKE) runcmdJ CMD="show configuration devices device ER-3 config | display xml | save config/original-ER-3.xml"
	@$(MAKE) runcmdJ CMD="request devices device ER-3 delete-config"
	@$(MAKE) runcmdJ CMD="request nodes router ER-3 re-deploy no-networking"
	@$(MAKE) runcmdJ CMD="show configuration devices device ER-3 config | display xml | save config/new-ER-3.xml"
	diff -u config/original-ER-3.xml config/new-ER-3.xml || true
	@$(MAKE) runcmdJ CMD="request devices device ER-3 sync-from"

# And again for the CFS
tutorial-sd-33-find-services-l3vpn-dry-run:
	@$(MAKE) runcmdJ CMD="request l3vpn find-services dry-run"

# and for L3VPN for realz
tutorial-sd-34-find-services-l3vpn:
	@$(MAKE) runcmdJ CMD="request l3vpn find-services"
	diff -u config/original-ER-3.xml config/new-ER-3.xml || true
# Et voila! Back in sync again. We have now demonstrated the three main cases
# for how a device can deviate from the configuration produced by NSO and how to
# address those cases.

# Keep iterating like this for your network until you have 0 diff - you're done.
# Service Discovery is finally over, you've killed the boss and have exited the
# nether^wbrownfield domain. At this point, service discovery code can be
# deleted and the service YANG model can be tightened up by applying more strict
# constraints on the input. Note that in order to preserve this utopian state,
# all future changes into the network must come from NSO services. Out of band
# changes directly on devices is strictly forbidden, or at least will be
# overwritten by services. Accepting out of band changes would bring the network
# / NSO back into "brownfield" state and reintroduce the need for service
# discovery... so don't do it.

## END OF TUTORIAL
