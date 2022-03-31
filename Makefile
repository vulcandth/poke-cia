### Virtual Console repacking stuff

## "Option" variables, intended to be overridden from the command line
# (Or from `config.mk` if you want to persist those)

# Clear this to let ctrtool speak its mind. It is quite talkative.
VERBOSE_CTRTOOL := >/dev/null

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

# Calls for the pret repo to check for updates, then checks if the .cias need to be updated
.PHONY: update
update:
	$(MAKE) -C ${repo_path} $(subst poke,,${rom_names}) $(subst poke,,$(addsuffix _vc, ${rom_names}))
	$(MAKE) ${cias}

# Tides up poke-cia
.PHONY: tidy
tidy:
	rm -f ${cias} ${game_cxis} ${manual_cfas}

# Cleans the poke-cia directory back to a near pristine state.
.PHONY: clean
clean: tidy
	rm -rf ${rom_dirs}

# Tidies up the pret repo and the poke-cia repo.
.PHONY: prettidy
prettidy: tidy
	$(MAKE) -C ${repo_path} tidy

# Cleans the pret repo and the poke-cia repo.
.PHONY: pretclean
pretclean: clean
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
	           $< ${VERBOSE_CTRTOOL}
	${CTRTOOL} --cidx 1 \
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
$(foreach rom,${rom_names},$(eval $(call copy_patch_rule,${rom})))

define copy_rom_rule
$(1)/romfs/rom/$(1): $${repo_path}/$(1).gbc | $(1)/
	mkdir -p $${@D}
	cp -T $$< $$@
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
%.manual.cfa: manual.rsf
	env -C $* \
	    ${MAKEROM} -f cfa -o ../$@ -rsf ../$<

%.cia: %.game.cxi %.manual.cfa
	${MAKEROM} -f cia -o $@ -content $<:0:0 -content $*.manual.cfa:1:1

# Catch-all rules for files originating from the source repo

${repo_path}/%:
	$(MAKE) -C ${@D} ${@F}
