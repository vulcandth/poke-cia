### Virtual Console repacking stuff

vc_dir := poke-cia

# Include Configuration Settings
include ${vc_dir}/cia-config.mk
ifeq ($(strip ${vc_name}),)
$(error Please set the `vc_name` variable in ${vc_dir}/cia-config.mk)
endif

vc_rom_dirs   := $(addprefix ${vc_dir}/, ${vc_name})
vc_cias       := $(addsuffix .cia, ${vc_rom_dirs})
vc_orig_cia   := $(addsuffix .orig.cia, ${vc_rom_dirs})
vc_game_cxi   := $(addsuffix .game.cxi, ${vc_rom_dirs})
vc_manual_cfa := $(addsuffix .manual.cfa, ${vc_rom_dirs})


# "Interface" rules

.PHONY: cia
cia: ${vc_cias}

.PHONY: clean
clean: clean_cia

.PHONY: clean_cia
clean_cia:
	rm -f ${vc_cias} ${vc_game_cxi} ${vc_manual_cfa}

.PHONY: distclean_cia
distclean_cia: clean_cia
	rm -rf ${vc_rom_dirs} ${vc_dir}/seeddb.bin


# Actual rules

# TODO: relying on directory modification time is a bad idea!
# Silence `ctrtool`, which is VERY verbose by default
${vc_dir}/%/: ${vc_dir}/%.orig.cia ${vc_dir}/seeddb.bin
	mkdir -p $@
	ctrtool --contents=$@contents $< >/dev/null
	ctrtool --seeddb=${vc_dir}/seeddb.bin \
	        --exheader=$@exheader.bin \
	        --exefsdir=$@exefs \
	        --romfsdir=$@romfs \
	        --logo=$@logo.lz \
	        --plainrgn=$@plain.bin \
	        $@contents.0000.* >/dev/null
	ctrtool --seeddb=${vc_dir}/seeddb.bin \
	        --romfsdir=$@manual \
	        $@contents.0001.* >/dev/null
	rm -f $@contents.*
	rm -f $@romfs/rom/*
	rm -f $@romfs/*.patch

# romfs files have the pattern appear twice in the path, which breaks pattern rules; we have to use `eval` instead
# Careful that the contents of the `define`s are expanded twice:
# 1. In the `call` function, and
# 2. In the `eval` function.

define copy_patch_rule
$${vc_dir}/$(1)/romfs/$(1).patch: $(1).patch | ${vc_dir}/$(1)/
	mkdir -p $${@D}
	cp -T $$< $$@
endef
$(foreach vc,${vc_name},$(eval $(call copy_patch_rule,${vc})))

define copy_rom_rule
$${vc_dir}/$(1)/romfs/rom/$(1): $(1).gbc | ${vc_dir}/$(1)/
	mkdir -p $${@D}
	cp -T $$< $$@
endef
$(foreach vc,${vc_name},$(eval $(call copy_rom_rule,${vc})))

define make_cxi_rule
$${vc_dir}/$(1).game.cxi: $${vc_dir}/game.rsf $${vc_dir}/$(1)/romfs/$(1).patch $${vc_dir}/$(1)/romfs/rom/$(1)
	makerom -f cxi -o $$@ -rsf $$< \
	        -exheader $${vc_dir}/$(1)/exheader.bin \
	        -logo $${vc_dir}/$(1)/logo.lz \
	        -plainrgn $${vc_dir}/$(1)/plain.bin \
	        -code $${vc_dir}/$(1)/exefs/code.bin \
	        -icon $${vc_dir}/$(1)/exefs/icon.bin \
	        -banner $${vc_dir}/$(1)/exefs/banner.bin
endef
$(foreach vc,${vc_name},$(eval $(call make_cxi_rule,${vc})))

${vc_dir}/%.manual.cfa: ${vc_dir}/manual.rsf
	makerom -f cfa -o $@ -rsf $<

${vc_dir}/%.cia: ${vc_dir}/%.game.cxi ${vc_dir}/%.manual.cfa
	makerom -f cia -o $@ -content $<:0:0 -content ${vc_dir}/$*.manual.cfa:1:1
