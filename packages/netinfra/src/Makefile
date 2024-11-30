all: fxs pre-compile
.PHONY: all

# Include standard NCS examples build definitions and rules
include $(NCS_DIR)/src/ncs/build/include.ncs.mk

SRC = $(wildcard yang/*.yang)
STRIPPED_YANG = $(wildcard yang/*stripped.yang)
SRC := $(filter-out $(STRIPPED_YANG), $(SRC))
DIRS = ../load-dir
FXS = $(SRC:yang/%.yang=../load-dir/%.fxs)
FXS += $(STRIP_TARGET:yang/%.yang=../load-dir/%.fxs)

include ./pre-compile.mk


YANGPATH += \
../../netinfra/src/yang \

NCSCPATH   = $(YANGPATH:%=--yangpath %)
YANGERPATH = $(YANGPATH:%=--path %)

fxs: $(DIRS) $(FXS)

$(DIRS):
	mkdir -p $@

../load-dir/%.fxs: yang/%.yang
	$(NCSC)  `ls $*-ann.yang  > /dev/null 2>&1 && echo "-a $*-ann.yang"` \
		--fail-on-warnings \
		$(NCSCPATH) \
		-c -o $@ $<

clean:
	rm -rf $(DIRS)
.PHONY: clean
