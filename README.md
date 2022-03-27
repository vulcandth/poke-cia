CIA building extension for Pret Pokemon Gen I / II Repos
======================================

This repo provides a simple extension that integrates the build of a Virtual Console .cia file to the pret pokemon Gen I / II repos, to ease the building of a VC .cia for your ROM Hack down to something as simple as `make cia`.

Requirements
------------

* A recent [pokecrystal](https://github.com/pret/pokecrystal), [pokegold](https://github.com/pret/pokegold), [pokered](https://github.com/pret/pokered), or [pokeyellow](https://github.com/pret/pokeyellow) installation, that supports building Virtual Console patches.
* An original (encrypted or decrypted) `.cia` file.
* [ctrtool and makerom](https://github.com/profi200/Project_CTR) (Only master has been tested)
* Obtain `seeddb.bin`, here is a link: [seeddb.bin](https://github.com/ihaveamac/3DS-rom-tools/raw/master/seeddb/seeddb.bin)

Obtaining the original file is outside of the scope of this document. It can be legally obtained by extracting it from your console through tools such as GodMode9 and/or FunkyCIA.

Run `make` to build both `ctrtool` and `makerom`, and put them in your `$PATH`.

Installation
------------

To install, you need to clone the `poke-cia` repo into your Pret repository. The following is a pokecrystal example:

```shell
cd <path to pokecrystal>
git clone https://github.com/vulcandth/poke-cia poke-cia
echo "-include poke-cia/cia.mk" >> Makefile
```

Next you will need to create your `poke-cia/cia-config.mk` file by using `poke-cia/cia-config.mk.template` as a base. 

```shell
cp ./poke-cia/cia-config.mk.template ./poke-cia/cia-config.mk
```

Modify your `/poke-cia/cia-config.mk` file using a text editor of your choice, adjusting the following line to match the pret repository your are using. In this example we are using `pret/pokecrystal`

```makefile
vc_name       := $(vc_crystal_name)
```

Copy your original dumped .cia files to `poke-cia/<build_name>.orig.cia`. Where `<build_name>` represents the names of the `.gbc` files that is output from your installed pret repository. In the case of Pokemon Crystal, it should be:

 `poke-cia/pokecrystal11.orig.cia`

Finally place your obained `seeddb.bin` file inside your `poke-cia` directory.

Now you can run `make cia` and be on your merry way!
