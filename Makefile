# poke-cia Makefile
# This file is part of the poke-cia project, which provides tools
# for repackaging Nintendo 3DS Virtual Console (VC) .cia files 
# using built .gbc(s) and .patch(s) from the pret Pokémon Gen I/II repos.
#
# -------------------------------------
# The Unlicense
# 
# This is free and unencumbered software released into the public domain.
# 
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
# 
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
# 
# For more information, please refer to <http://unlicense.org/>
# -------------------------------------

### Virtual Console repacking stuff

## "Option" variables, intended to be overridden from the command line
# (Or from `config.mk` if you want to persist those)

# Clear this to let ctrtool speak its mind. It is quite talkative.
VERBOSE_CTRTOOL := -q

# Paths to the executables (mind that lack of slashes means PATH will be searched instead!)
CTRTOOL := ctrtool
MAKEROM := makerom


# Include Configuration Settings

include config.mk
ifeq ($(strip ${rom_names}),)
$(error Please set the `rom_names` variable in config.mk)
endif
ifeq ($(strip ${repo_path}),)
$(error Please set the `repo_path` variable in config.mk)
endif

# Convenience lists
rom_dirs    := ${rom_names}
cias        := $(addsuffix .cia, ${rom_names})
orig_cias   := $(addsuffix .orig.cia, ${rom_names})
game_cxis   := $(addsuffix .game.cxi, ${rom_names})
manual_cfas := $(addsuffix .manual.cfa, ${rom_names})
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

# Calls for the rom's repo to check for updates, then checks if the .cias need to be updated
.PHONY: repoupdate
repoupdate:
	$(MAKE) -C ${repo_path} $(rom_targets)

# Tides up poke-cia
.PHONY: tidy
tidy:
	rm -f ${cias} ${game_cxis} ${manual_cfas}

# Cleans the poke-cia directory back to a near pristine state.
.PHONY: clean
clean: tidy
	rm -rf ${rom_dirs}

# Tidies up the rom's repo and the poke-cia repo.
.PHONY: repotidy
repotidy: tidy
	$(MAKE) -C ${repo_path} tidy

# Cleans the rom's repo and the poke-cia repo.
.PHONY: repoclean
repoclean: clean
	$(MAKE) -C ${repo_path} clean


# Actual rules

# Rules that update the romfs files must run after this (since it extracts all original files),
# so they are given an order-only dep on the directory (`%/` here).
# Do NOT depend on it directly, as directory modification times update in unintuitive ways!
#
# This extracts the original CIA's contents, deletes the original ROM, and deletes all patch files. 
# (There are extra, un-needed patch files left in by the VC developers for the other games.)
#
# Silence `ctrtool`, which is VERY verbose by default (sadly that may also suppress debug info)
%/ $(addprefix %/,${cxi_deps}): %.orig.cia seeddb.bin
	@mkdir -p $*
	${CTRTOOL} --cidx 0 \
	           --seeddb=seeddb.bin \
	           --exheader=$@exheader.bin \
	           --exefsdir=$@exefs \
	           --romfsdir=$@romfs \
	           --logo=$@logo.lz \
	           --plainrgn=$@plain.bin \
			   ${VERBOSE_CTRTOOL} \
	           $<
	${CTRTOOL} --cidx 1 \
	           --seeddb=seeddb.bin \
	           --romfsdir=$@manual \
			   ${VERBOSE_CTRTOOL} \
	           $<
	rm -f $@romfs/rom/*
	rm -f $@romfs/*.patch
	@if [ "$(build_mbc30)" = "true" ]; then \
		python3 mbc30patch.py ; \
	fi


# romfs files have the pattern appear twice in the path, which breaks pattern rules; we have to use `eval` instead
# Careful that the contents of the `define`s are expanded twice:
# 1. In the `call` function, and
# 2. In the `eval` function.

define copy_patch_rule
$(1)/romfs/$(1).patch: $(1)/ repoupdate
	mkdir -p $${@D}
	cp -T $${repo_path}/$(1).patch $$@
endef
$(foreach rom,${rom_names},$(eval $(call copy_patch_rule,${rom})))

define copy_rom_rule
$(1)/romfs/rom/$(1): $(1)/ repoupdate
	mkdir -p $${@D}
	cp -T $${repo_path}/$(1).gbc $$@
endef
$(foreach rom,${rom_names},$(eval $(call copy_rom_rule,${rom})))

# This rule must be run in the "extracted" directory for it to find all the files
define make_cxi_rule
$(1).game.cxi: game.rsf $(1)/romfs/$(1).patch $(1)/romfs/rom/$(1) $(addprefix $(1)/,${cxi_deps})
	env -C $(1)/ \
	    ${MAKEROM} -f cxi -o ../$$@ -rsf ../$$< \
	               -exheader exheader.bin \
	               -logo logo.lz \
	               -plainrgn plain.bin \
	               -code exefs/code.bin \
	               -icon exefs/icon.bin \
	               -banner exefs/banner.bin
endef
$(foreach rom,${rom_names},$(eval $(call make_cxi_rule,${rom})))

# This must also be run in the "extracted" directory
define make_cfa_rule
$(1).manual.cfa: manual.rsf $(1)/
	env -C $(1)/ \
	    ${MAKEROM} -f cfa -o ../$$@ -rsf ../$$<
endef
$(foreach rom,${rom_names},$(eval $(call make_cfa_rule,${rom})))

%.cia: %.game.cxi %.manual.cfa
	${MAKEROM} -f cia -o $@ -content $<:0:0 -content $*.manual.cfa:1:1
