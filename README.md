CIA building extension for Pret Pokemon Gen I / II Repos
======================================

This repo provides a simple extension that integrates the build of a Virtual Console .cia file to the pret pokemon Gen I / II repos, to ease the building of a VC .cia for your ROM Hack down to something as simple as `make cia`.

Requirements
------------

* A recent [pokecrystal](https://github.com/pret/pokecrystal), [pokegold](https://github.com/pret/pokegold), [pokered](https://github.com/pret/pokered), or [pokeyellow](https://github.com/pret/pokeyellow) installation, that supports building Virtual Console patches.
* An original (encrypted or decrypted) `.cia` file.
* [ctrtool and makerom](https://github.com/profi200/Project_CTR) (Only master has been tested)

Obtaining the original file is outside of the scope of this document. It can be legally obtained by extracting it from your console through tools such as GodMode9 and/or FunkyCIA.

Run `make` to build both `ctrtool` and `makerom`, and put them in your `$PATH`.

Installation
------------

It shouldn't be more complicated than the following pokecrystal example:

```
cd <path to pokecrystal>
git clone https://github.com/vulcandth/poke-cia poke-cia
echo "-include poke-cia/cia.mk" >> Makefile
```

Copy your original .cia file to `vc/<Title ID>.cia`. Where `<Title ID>` is the 16 digit number representing your base game's title ID. In the case of Pokemon Crystal, it should be `poke-cia/0004000000172800.cia`

Now you can run `make cia` and be on your merry way!
