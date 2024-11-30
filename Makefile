ifeq "$(NCS_DIR)" ""
$(error NCS_DIR is not setup. Source ncsrc to setup NSO environment before proceeding)
endif

JUNOS_EXISTS = $(shell ls packages/juniper-junos-nc-4.16)
ifeq "$(JUNOS_EXISTS)" ""
$(error Juniper Junos NED not found in packages dir. Please download the NED package juniper-junos-nc-4.16 before proceeding)
endif

RM = $(shell ls packages/resource-manager)
ifeq "$(RM)" ""
$(error Resource Manager NED not found in packages dir. Please download the resource-manager package before proceeding)
endif

NSO_VERSION = $(shell ncs --version)
NSO_VER_MAJ = $(shell echo $(NSO_VERSION) | cut -f1 -d.)
NSO_VER_MIN = $(shell echo $(NSO_VERSION) | cut -f2 -d. | cut -f1 -d_)
NSO_MAJOR_VERSION = $(NSO_VER_MAJ).$(NSO_VER_MIN)

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PACKAGES = $(wildcard packages/*)
TARGET_DIR = ncs-run
TARGET_SETUP = $(TARGET_DIR)
NCS_SETUP = ncs-setup
NCS_CLI = ncs_cli
ENV_VARS = 
NCS = ncs
LUX_FILES = $(wildcard *.lux)
NETSIM = ncs-netsim

all:
	@echo "NSO major version: $(NSO_MAJOR_VERSION) ($(NSO_VERSION))"
	@echo
	@echo "Makefile rules:"
	@echo " build               	Build the environment. Do this before starting the tutorial"
	@echo " rebuild             	Rebuild the service packages and reload them on NSO"
	@echo " reset                	Stop, clean and recreate NSO and netsims without building packages"
	@echo " start               	Start NSO and netsims. This is done automatically by the tutorial"
	@echo " stop                	Stop NSO and netsims"
	@echo " tutorial-sd-1-start  	Start the tutorial"
	@echo " tutorial-sd-n-*     	Run the rest of the tutorial (n = 1..32)"
.PHONY: all

include tutorial.mk

clean: clean_packages
	rm -rf ncs-run
	rm -rf netsim
	rm -f netsim_init.xml
	rm -rf config
.PHONY: clean

build: make_packages $(TARGET_SETUP) link_packages setup_netsim
.PHONY: build

$(TARGET_SETUP):
	$(NCS_SETUP) --dest $(TARGET_DIR)
	mkdir config

reset: stop
	rm -rf ncs-run
	rm -rf netsim
	rm -f netsim_init.xml
	rm -rf config
	$(MAKE) $(TARGET_SETUP)
	$(MAKE) link_packages
	$(MAKE) setup_netsim
.PHONY: reset

rebuild:
	$(MAKE) -C packages/respl3vpn/src clean all
	$(MAKE) -C packages/netinfra/src clean all
	$(MAKE) -C packages/netinfra-rfs/src clean all
	$(MAKE) runcmdJ CMD="request packages reload"
.PHONY: rebuild

make_packages: $(PACKAGES)
	$(foreach pkg, $(PACKAGES), \
	  if [ -d "$(pkg)" ]; then $(MAKE) -C"$(pkg)/src" all; fi &&) true
	$(MAKE) -C patches/leftover-config/src all
.PHONY: make_packages

cli:
	$(ENV_VARS) $(NCS_CLI) -u admin -g admin
.PHONY: cli

clean_packages:
	$(foreach pkg, $(PACKAGES), \
	  if [ -d "$(pkg)" ]; then $(MAKE) -C $(pkg)/src clean; fi; )
	$(MAKE) -C patches/leftover-config/src clean
.PHONY: clean_packages

link_packages:
	$(foreach pkg, $(PACKAGES), \
	  if [ -d "$(pkg)" ]; then ln -sf ../../$(pkg) $(TARGET_DIR)/packages/ ; fi &&) true
.PHONY: link_packages 

clean_cdb:
	rm -f $(TARGET_DIR)/ncs-cdb/*.cdb
.PHONY: clean_cdb

start: start_netsim 
	(cd $(TARGET_DIR); $(NCS))
.PHONY: start
stop: stop_netsim
	$(NCS) --stop || true
.PHONY: stop
start_netsim:
	$(NETSIM) start
.PHONY: start_netsim
stop_netsim:
	$(NETSIM) stop || true
.PHONY: stop_netsim

setup_netsim:
	ncs-netsim create-device ./packages/juniper-junos-nc-4.16 CR-1
	ncs-netsim add-device ./packages/juniper-junos-nc-4.16 CR-2
	ncs-netsim add-device ./packages/juniper-junos-nc-4.16 CR-3
	ncs-netsim add-device ./packages/juniper-junos-nc-4.16 ER-1
	ncs-netsim add-device ./packages/juniper-junos-nc-4.16 ER-2
	ncs-netsim add-device ./packages/juniper-junos-nc-4.16 ER-3
	ncs-netsim ncs-xml-init > netsim_init.xml
.PHONY: setup_netsim

COLOUR_GREEN=\033[0;32m
COLOUR_END=\033[0m

runcmdJ:
	@echo "$(COLOUR_GREEN)NSO CLI input:$(COLOUR_END) \n"
	@printf "$(CMD)\n\n"
	@echo "$(COLOUR_GREEN)NSO CLI output:$(COLOUR_END) \n"
	@printf "unhide debug\n$(CMD)\n" | ncs_cli --stop-on-error -u admin
	@printf "\n"
.PHONY: runcmdJ

loadconf:
	@$(MAKE) runcmdJ CMD="configure\nload merge $(FILE)\ncommit"
.PHONY: loadconf

configure:
	@$(MAKE) loadconf FILE=nso-config/init.xml
.PHONY: configure

configure-resource-pools:
	@$(MAKE) loadconf FILE=nso-config/config-resource-pools.xml
.PHONY: configure-resource-pools

netsim-load-xml-conf:
	printf "configure\nload merge $(ROOT_DIR)/$(FILE)\ncommit\n" | ncs-netsim cli $(NETSIM)
.PHONY: netsim-load-xml-conf
