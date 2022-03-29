### Virtual Console repacking stuff

## "Option" variables, intended to be overridden from the command line
# (Or from `config.mk` if you want to persist those)

# Clear this to let ctrtool speak its mind. It is quite talkative.
VERBOSE_CTRTOOL := >/dev/null

# Include Configuration Settings
include config.mk
ifeq ($(strip ${roms_names}),)
$(error Please set the `roms_names` variable in config.mk)
endif
ifeq ($(strip ${repo_path}),)
$(error Please set the `repo_path` variable in config.mk)
endif

# Convenience lists
rom_dirs    := ${roms_names}
cias        := $(addsuffix .cia, ${roms_names})
orig_cias   := $(addsuffix .orig.cia, ${roms_names})
game_cxis   := $(addsuffix .game.cxi, ${roms_names})
manual_cfas := $(addsuffix .manual.cfa, ${roms_names})
# List of files upon which a CXI file depends
cxi_deps    = exheader.bin logo.lz plain.bin exefs/banner.bin exefs/code.bin $(shell [ -e romfs ] && find romfs -type f)


# "Interface" rules

# Build the CIAs.
.PHONY: cia
cia: ${cias}

# Extract the `.orig.cia`s, but don't build the CIAs.
# Does not re-extract if the directories if they are already present; use `distclean` for that.
.PHONY: extract
# Ok to depend on the directories, as this target is phony thus never up to date anyway
extract: $(addsuffix /,${rom_dirs})

.PHONY: clean
clean:
	rm -f ${cias} ${game_cxis} ${manual_cfas}

.PHONY: distclean
distclean: clean
	rm -rf ${rom_dirs}


# Actual rules

# Rules that update the romfs files must run after this (since it extracts all original files),
# so they are given an order-only dep on the directory (`%/` here).
# Do NOT depend on it directly, as directory modification times update in unintuitive ways!
#
# This extracts the original CIA's contents, but deletes the original ROM and patch
#
# Silence `ctrtool`, which is VERY verbose by default (sadly that may also suppress debug info)
%/ $(addprefix %/,${cxi_deps}): %.orig.cia seeddb.bin
	@mkdir -p $*
	ctrtool --cidx 0 \
	        --seeddb=seeddb.bin \
	        --exheader=$@exheader.bin \
	        --exefsdir=$@exefs \
	        --romfsdir=$@romfs \
	        --logo=$@logo.lz \
	        --plainrgn=$@plain.bin \
	        $< ${VERBOSE_CTRTOOL}
	ctrtool --cidx 1 \
	        --seeddb=seeddb.bin \
	        --romfsdir=$@manual \
	        $< ${VERBOSE_CTRTOOL}
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
$(foreach rom,${roms_names},$(eval $(call copy_patch_rule,${rom})))

define copy_rom_rule
$(1)/romfs/rom/$(1): $${repo_path}/$(1).gbc | $(1)/
	mkdir -p $${@D}
	cp -T $$< $$@
endef
$(foreach rom,${roms_names},$(eval $(call copy_rom_rule,${rom})))

# This rule must be run in the "extracted" directory for it to find all the files
define make_cxi_rule
$(1).game.cxi: game.rsf $(1)/romfs/$(1).patch $(1)/romfs/rom/$(1) $(addprefix $(1)/,${cxi_deps})
	env -C $(1)/ \
	    makerom -f cxi -o ../$$@ -rsf ../$$< \
	            -exheader exheader.bin \
	            -logo logo.lz \
	            -plainrgn plain.bin \
	            -code exefs/code.bin \
	            -icon exefs/icon.bin \
	            -banner exefs/banner.bin
endef
$(foreach rom,${roms_names},$(eval $(call make_cxi_rule,${rom})))

%.manual.cfa: manual.rsf
	makerom -f cfa -o $@ -rsf $<

# This must also be run in the "extracted" directory
%.cia: %.game.cxi %.manual.cfa
	env -C $* \
	    makerom -f cia -o $@ -content ../$<:0:0 -content ../$*.manual.cfa:1:1

# Catch-all rules for files originating from the source repo

${repo_path}/%:
	make -C ${@D} ${@F}
