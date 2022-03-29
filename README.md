# CIA building extension for Pret Pokemon Gen I / II Repos

This repo provides a simple extension that integrates the build of a Virtual Console .cia file to the pret pokemon Gen I / II repos, to ease the building of a VC .cia for your ROM Hack down to something as simple as `make cia`.

## Requirements

* A recent [pokecrystal](https://github.com/pret/pokecrystal), [pokegold](https://github.com/pret/pokegold), [pokered](https://github.com/pret/pokered), or [pokeyellow](https://github.com/pret/pokeyellow) installation, that supports building Virtual Console patches.
* An original (encrypted or decrypted) `.cia` file.
* [ctrtool and makerom](https://github.com/profi200/Project_CTR) (Only master has been tested)
* Obtain `seeddb.bin`, here is a link: [seeddb.bin](https://github.com/ihaveamac/3DS-rom-tools/raw/master/seeddb/seeddb.bin)

Obtaining the original file is outside of the scope of this document. It can be legally obtained by extracting it from your console through tools such as GodMode9 and/or FunkyCIA.

Run `make` to build both `ctrtool` and `makerom`, and put them in your `$PATH`.

## Installation

First, [clone this repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository), and `cd` into it.

Next, you will need to create your `config.mk` file by using `config.mk.template` as a base. 

```console
% cp config.mk.template config.mk
```

Modify this new `config.mk` file using a text editor of your choice.

Define `vc_name` to match the name of the ROM you want to build the `.cia` from, sans file extension.
For example, for Pokémon Crystal, you can uncomment one of the example lines:

```makefile
vc_name    := pokecrystal11
```

(There should not be more than one uncommented line at a given time.)
You can also build more than one `.cia` at a time!
Simply write a space-separated list of names instead:

```makefile
vc_name    := redstar bluestar
```

Still in that same file, you must also set the `repo_path` variable to point to the repository containing the ROMs, for example:

```makefile
repo_path  := ../pokered
```

(Relative paths must be relative to the `poke-cia` directory.)

Copy your original dumped .cia files to `<build_name>.orig.cia`, where `<build_name>` is one of the names you put in `vc_name`.
For example, for Pokémon Crystal, it should be `pokecrystal11.orig.cia`.

Finally, place your obained `seeddb.bin` file inside your `poke-cia` directory.

Now, you can run `make` and be on your merry way!
The new `.cia` files will be generated in the same directory.
