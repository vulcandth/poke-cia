### Virtual Console repacking stuff

# Include Configuration Settings
include config.mk
ifeq ($(strip ${vc_name}),)
$(error Please set the `vc_name` variable in config.mk)
endif
ifeq ($(strip ${repo_path}),)
$(error Please set the `repo_path` variable in config.mk)
endif

vc_rom_dirs   := ${vc_name}
vc_cias       := $(addsuffix .cia, ${vc_rom_dirs})
vc_orig_cia   := $(addsuffix .orig.cia, ${vc_rom_dirs})
vc_game_cxi   := $(addsuffix .game.cxi, ${vc_rom_dirs})
vc_manual_cfa := $(addsuffix .manual.cfa, ${vc_rom_dirs})


# "Interface" rules

.PHONY: cia
cia: ${vc_cias}

.PHONY: clean
clean:
	rm -f ${vc_cias} ${vc_game_cxi} ${vc_manual_cfa}

.PHONY: distclean
distclean: clean
	rm -rf ${vc_rom_dirs} seeddb.bin


# Actual rules

# TODO: relying on directory modification time is a bad idea!
# Silence `ctrtool`, which is VERY verbose by default
# This extracts the original CIA's contents, but deletes the original ROM and patch
%/: %.orig.cia seeddb.bin
	mkdir -p $@
	ctrtool --cidx 0 \
	        --seeddb=seeddb.bin \
	        --exheader=$@exheader.bin \
	        --exefsdir=$@exefs \
	        --romfsdir=$@romfs \
	        --logo=$@logo.lz \
	        --plainrgn=$@plain.bin \
	        $< >/dev/null
	ctrtool --cidx 1 \
	        --seeddb=seeddb.bin \
	        --romfsdir=$@manual \
	        $< >/dev/null
	rm -f $@romfs/rom/*
	rm -f $@romfs/*.patch

# romfs files have the pattern appear twice in the path, which breaks pattern rules; we have to use `eval` instead
# Careful that the contents of the `define`s are expanded twice:
# 1. In the `call` function, and
# 2. In the `eval` function.

define copy_patch_rule
$(1)/romfs/$(1).patch: $${repo_path}/$(1).patch | $(1)/
	mkdir -p $${@D}
	cp -T $$< $$@
endef
$(foreach vc,${vc_name},$(eval $(call copy_patch_rule,${vc})))

define copy_rom_rule
$(1)/romfs/rom/$(1): $${repo_path}/$(1).gbc | $(1)/
	mkdir -p $${@D}
	cp -T $$< $$@
endef
$(foreach vc,${vc_name},$(eval $(call copy_rom_rule,${vc})))

# This rule must be run in the "extracted" directory for it to find all the files
define make_cxi_rule
$(1).game.cxi: game.rsf $(1)/romfs/$(1).patch $(1)/romfs/rom/$(1)
	env -C $(1)/ \
	    makerom -f cxi -o ../$$@ -rsf ../$$< \
	            -exheader exheader.bin \
	            -logo logo.lz \
	            -plainrgn plain.bin \
	            -code exefs/code.bin \
	            -icon exefs/icon.bin \
	            -banner exefs/banner.bin
endef
$(foreach vc,${vc_name},$(eval $(call make_cxi_rule,${vc})))

%.manual.cfa: manual.rsf
	makerom -f cfa -o $@ -rsf $<

# This must also be run in the "extracted" directory
%.cia: %.game.cxi %.manual.cfa
	env -C $* \
	    makerom -f cia -o $@ -content ../$<:0:0 -content ../$*.manual.cfa:1:1

# Catch-all rules for files originating from the source repo

${repo_path}/%:
	make -C ${@D} ${@F}
