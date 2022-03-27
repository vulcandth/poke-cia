### Virtual Console repacking stuff

# Include Configuration Settings
vc_dir := poke-cia
-include $(vc_dir)/cia-config.mk

.PHONY: cia
cia: $(vc_cia)

.PHONY: clean
clean: clean_cia

.PHONY: clean_cia
clean_cia:
	rm -f $(vc_cia) $(vc_game_cxi) $(vc_manual_cfa)

.PHONY: distclean_cia
distclean_cia: clean_cia
	rm -rf $(vc_rom_dir) $(vc_dir)/seeddb.bin

$(vc_dir)/seeddb.bin:
	wget -O $@ 'https://github.com/ihaveamac/3DS-rom-tools/raw/master/seeddb/seeddb.bin'

$(vc_rom_dir): $(vc_orig_cia) $(vc_dir)/seeddb.bin
	mkdir -p $@
	ctrtool --contents=$@/contents $@.orig.cia
	ctrtool --seeddb=$(vc_dir)/seeddb.bin \
	        --exheader=$@/exheader.bin \
	        --exefsdir=$@/exefs \
	        --romfsdir=$@/romfs \
	        --logo=$@/logo.lz \
	        --plainrgn=$@/plain.bin \
	        $@/contents.0000.*
	ctrtool --seeddb=$(vc_dir)/seeddb.bin \
	        --romfsdir=$@/manual \
	        $@/contents.0001.*
	rm -f $@/contents.*
	rm -f $@/romfs/rom/*
	rm -f $@/romfs/*.patch

$(join $(addsuffix /romfs/, $(vc_rom_dir)), $(vc_patch)): $(vc_rom_dir) ./$(vc_patch)
	cp ./$(notdir $@) $@
	
$(join $(addsuffix /romfs/rom/, $(vc_rom_dir)), $(vc_gbc)): $(vc_rom_dir) ./$(vc_gbc)
	cp ./$(notdir $@) $(basename $@)

$(vc_game_cxi): $(vc_rom_dir) $(join $(addsuffix /romfs/, $(vc_rom_dir)), $(vc_patch)) $(join $(addsuffix /romfs/rom/, $(vc_rom_dir)), $(vc_gbc))
	(cd $(basename $(basename $@))/; \
	    makerom -f cxi -o ../../$(basename $@).cxi -rsf ../game.rsf \
	            -exheader exheader.bin \
	            -logo logo.lz \
	            -plainrgn plain.bin \
	            -code exefs/code.bin \
	            -icon exefs/icon.bin \
	            -banner exefs/banner.bin \
	)

$(vc_manual_cfa): $(vc_dir)/manual.rsf
	makerom -f cfa -o $@ -rsf $(vc_dir)/manual.rsf

$(vc_cia): $(vc_game_cxi) $(vc_manual_cfa)
	makerom -f cia -o $@ -content $(basename $@).game.cxi:0:0 -content $(basename $@).manual.cfa:1:1