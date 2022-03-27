### Virtual Console repacking stuff

vc_dir := poke-cia
vc_name := pokecrystalvc

vc_titleid := 0004000000172800
vc_rom := $(vc_dir)/rom
vc_game := $(addprefix $(vc_rom)/, exheader.bin logo.lz plain.bin exefs/banner.bin exefs/code.bin exefs/icon.bin romfs/)
vc_manual := $(vc_rom)/manual

.PHONY: cia
cia: $(vc_dir)/$(vc_name).cia

.PHONY: clean
clean: clean_cia

.PHONY: clean_cia
clean_cia:
	rm -f $(vc_dir)/$(vc_name).cia $(vc_dir)/game.cxi $(vc_dir)/manual.cfa

.PHONY: distclean_cia
distclean_cia: clean_cia
	rm -rf $(vc_rom) $(vc_dir)/$(vc_titleid).key

$(vc_dir)/$(vc_name).cia: $(vc_dir)/game.cxi $(vc_dir)/manual.cfa
	makerom -f cia -o $@ -content $(vc_dir)/game.cxi:0:0 -content $(vc_dir)/manual.cfa:1:1

$(vc_dir)/game.cxi: $(vc_dir)/game.rsf $(vc_game)
	( cd $(vc_rom); \
		makerom -f cxi -o ../game.cxi -rsf ../game.rsf \
		        -exheader exheader.bin \
		        -logo logo.lz \
		        -plainrgn plain.bin \
		        -code exefs/code.bin \
		        -icon exefs/icon.bin \
		        -banner exefs/banner.bin \
	)

$(vc_dir)/manual.cfa: $(vc_dir)/manual.rsf $(vc_manual)
	( cd $(vc_rom); \
	    makerom -f cfa -o ../manual.cfa -rsf ../manual.rsf \
	)

# Populate romfs with built files
$(vc_rom)/romfs/: $(vc_rom)/romfs/rom/CGBBYTE1.784 $(vc_rom)/romfs/CGBBYTE1.784.patch
$(vc_rom)/romfs/rom/CGBBYTE1.784: pokecrystal11.gbc | $(vc_rom)
	cp $< $@
$(vc_rom)/romfs/CGBBYTE1.784.patch: pokecrystal11.patch | $(vc_rom)
	cp $< $@

# Update whenever the contents change
$(vc_rom)/romfs/: $(shell find $(vc_rom)/romfs/ -mindepth 1 2> /dev/null)
	touch $@
$(vc_rom)/manual/: $(shell find $(vc_rom)/manual/ -mindepth 1 2> /dev/null)
	touch $@

# Extract all the files
$(vc_game) $(vc_manual): $(vc_rom)
$(vc_rom): | $(vc_dir)/$(vc_titleid).cia $(vc_dir)/$(vc_titleid).key
	mkdir -p $@
	ctrtool --contents=$@/contents $(vc_dir)/$(vc_titleid).cia
	ctrtool --seeddb=$(vc_dir)/$(vc_titleid).key \
	        --exheader=$@/exheader.bin \
	        --exefsdir=$@/exefs \
	        --romfsdir=$@/romfs \
	        --logo=$@/logo.lz \
	        --plainrgn=$@/plain.bin \
	        $@/contents.0000.*
	ctrtool --seeddb=$(vc_dir)/$(vc_titleid).key \
	        --romfsdir=$@/manual \
	        $@/contents.0001.*
	rm -f $@/contents.*
	rm -f $@/romfs/rom/*
	rm -f $@/romfs/CGBBYTE1.784.patch

$(vc_dir)/%.key:
	wget -O $@ 'https://github.com/ihaveamac/3DS-rom-tools/raw/master/seeddb/seeddb.bin'

$(vc_dir)/%.cia:
	@echo "Could not find $@."
	@exit 1
