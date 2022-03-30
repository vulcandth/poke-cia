# CIA building extension for Pret Pokémon Gen I / II Repos

This repo provides a simple extension that repackages a Nintendo 3DS Virtual Console (VC) `.cia` file using the built `.gbc`(s) and `.patch`(s) generated from the Pret Pokémon Gen I / II repos. This will ease the building of a VC `.cia` for your ROM Hack down to something as simple as typing `make`.

## Requirements

* The hack's source repository. It must be based on a recent enough version of the original disassembly, so that it supports building Virtual Console patches:
  **Disassembly**                                    | **Must have been updated to this commit or later**
  ---------------------------------------------------|-------------------------------------------------------
  [pokered](https://github.com/pret/pokered)         | [fe8d3c51a4056f0dd61dbef332ad9e714b82089a](https://github.com/pret/pokered/commit/fe8d3c51a4056f0dd61dbef332ad9e714b82089a)
  [pokeyellow](https://github.com/pret/pokeyellow)   | [fbaa5c9d4b48c000a52860a8392fc423c4e312f9](https://github.com/pret/pokeyellow/commit/fbaa5c9d4b48c000a52860a8392fc423c4e312f9)
  [pokegold](https://github.com/pret/pokegold)       | [3d58fb95569be74c6c229118a425fa22628f1dc3](https://github.com/pret/pokegold/commit/3d58fb95569be74c6c229118a425fa22628f1dc3)
  [pokecrystal](https://github.com/pret/pokecrystal) | [31c3c94d64e1ac1e40c95acfda7de8b99b4f302b](https://github.com/pret/pokecrystal/commit/31c3c94d64e1ac1e40c95acfda7de8b99b4f302b)
* An original (encrypted or decrypted) `.cia` file for each version that you want to produce—see further below.
* [ctrtool](https://github.com/3DSGuy/Project_CTR) ctrtool v1.0.3 or later.
* [makerom](https://github.com/3DSGuy/Project_CTR) makerom v0.18 or later.
* `seeddb.bin`. It can be obtained [from this link](https://github.com/ihaveamac/3DS-rom-tools/raw/master/seeddb/seeddb.bin).

Obtaining the original file is outside of the scope of this document. It can be legally obtained by extracting it from your console through tools such as GodMode9 and/or FunkyCIA.

## Installation

First, [clone this repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository), and `cd` into it.

Next, you will need to create your `config.mk` file by using `config.mk.template` as a base.

```console
$ cp config.mk.template config.mk
```

Modify this new `config.mk` file using a text editor of your choice.

- Define `rom_names` to match the name of the ROM you want to build the `.cia` from, sans file extension.
  For example, for Pokémon Crystal, you can uncomment one of the example lines:

  ```makefile
  rom_names := pokecrystal11
  ```

  (There should not be more than one uncommented line at a given time.)
  You can also build more than one `.cia` at a time!
  Simply write a space-separated list of names instead:

  ```makefile
  rom_names := redstar bluestar
  ```

- Still in that same file, you must also set the `repo_path` variable to point to the repository containing the ROMs, for example:

  ```makefile
  repo_path  := ../pokered
  ```

  (Relative paths must be relative to the `poke-cia` directory.)

Copy and rename your original dumped .cia files to `<build_name>.orig.cia`, where `<build_name>` is one of the names you put in `rom_names`.
For example, for Pokémon Crystal, it should be `pokecrystal11.orig.cia`.

Finally, place your obained `seeddb.bin` file inside your `poke-cia` directory.

## Usage

Now, you can run `make` and be on your merry way!
The new `.cia` files will be generated in the same directory.
Both `makerom` and `ctrtool` must either be in your PATH, or you can pass the paths as arguments; for example:

```console
$ make MAKEROM=../ctrtool-v1.0.1/makerom/makerom CTRTOOL=../ctrtool-v1.0.1/ctrtool/bin/ctrtool
```

It is also possible to specify these variables in `config.mk` instead, which saves the trouble of re-typing them every time.

## Special Credits

I would like to give special credits to the following:
* @mid-kid originally came up with the idea of this tool and this extension is developed based on his orig repo.
* @ISSOtm spent a lot of time helping to restructure the extension, and getting it ready for release.
* @jakcron went out of their way to download not only one, but two other repos (this and pret) to help resolve a bug in ctrtool. 
