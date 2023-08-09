# CIA building extension for pret Pokémon Gen I / II Repos

This repo provides a simple extension that repackages a Nintendo 3DS Virtual Console (VC) `.cia` file using the built `.gbc`(s) and `.patch`(s) generated from the pret Pokémon Gen I / II repos. This will simplify building the VC `.cia` for your ROM Hack down to something as simple as typing `make`.

## Requirements

* The hack's source repository. It must be based on a recent enough version of the original disassembly, so that it supports building Virtual Console patches:
  
  | **Disassembly**                                    | **This commit or later**                                                                       |
  | -------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
  | [pokered](https://github.com/pret/pokered)         | [fe8d3c5](https://github.com/pret/pokered/commit/fe8d3c51a4056f0dd61dbef332ad9e714b82089a)     |
  | [pokeyellow](https://github.com/pret/pokeyellow)   | [fbaa5c9](https://github.com/pret/pokeyellow/commit/fbaa5c9d4b48c000a52860a8392fc423c4e312f9)  |
  | [pokegold](https://github.com/pret/pokegold)       | [3d58fb9](https://github.com/pret/pokegold/commit/3d58fb95569be74c6c229118a425fa22628f1dc3)    |
  | [pokecrystal](https://github.com/pret/pokecrystal) | [31c3c94](https://github.com/pret/pokecrystal/commit/31c3c94d64e1ac1e40c95acfda7de8b99b4f302b) |

* An original (encrypted or decrypted) `.cia` file for each version that you want to produce—see further below.

* [ctrtool](https://github.com/3DSGuy/Project_CTR) ctrtool v1.1.0 or later.

* [makerom](https://github.com/3DSGuy/Project_CTR) makerom v0.18 or later.

* `seeddb.bin`. It can be obtained [from this link](https://github.com/ihaveamac/3DS-rom-tools/raw/master/seeddb/seeddb.bin).

Obtaining the **original** `.cia` file dump is outside of the scope of this document. It can be legally obtained by extracting it from your console through tools such as GodMode9 and/or FunkyCIA.

## Installation

First, [clone this repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository), and `cd` into it.

Next, you will need to create your `config.mk` by copying from `config.mk.template`.

```console
$ cp config.mk.template config.mk
```

Modify this new `config.mk` file using a text editor of your choice.

- Define `rom_names` to match the name of the ROM you want to build the `.cia` from, without the file extension.
  For example, for Pokémon Crystal, you can uncomment one of the example lines:
  
  ```makefile
  rom_names := pokecrystal11
  ```
  
  (There should not be more than one uncommented line at a given time.)
  If you want to build multiple .cia files at once,
  Simply write a space-separated list of names instead:
  
  ```makefile
  rom_names := magenta turquoise
  ```

- In the same file, set the repo_path variable to point to the repository containing the ROMs. Note: The default repo_path assumes you're cloning into the ROM's repository.
  
  ```makefile
  repo_path := ../
  ```
  
  (Relative paths must be relative to the `poke-cia` directory. `../` means the directory above the poke-cia directory.)
  
- Finally, in that same file, set the rom_targets variable. Poke-cia uses this to run the appropriate make command build targets based on the repo_path variable.

  ```makefile
  repo_targets := red red_vc blue blue_vc
  ```

Copy and rename your original dumped .cia files to `<build_name>.orig.cia`, where `<build_name>` is one of the names you put in `rom_names`.
For example, for Pokémon Crystal, it should be `pokecrystal11.orig.cia`.

Finally, place your obtained `seeddb.bin` file inside your `poke-cia` directory.

## Usage

Now, you can run `make` and be on your merry way!
The new `.cia` files will be generated in the same directory.
Both `makerom` and `ctrtool` must either be in your PATH, or you can pass the paths as arguments; for example:

```console
$ make MAKEROM=../ctrtool-v1.0.1/makerom/makerom CTRTOOL=../ctrtool-v1.0.1/ctrtool/bin/ctrtool
```

It is also possible to specify these variables in `config.mk` instead, which saves the trouble of re-typing them every time.

The following is a list of notable poke-cia commands:

`make extract`: Extracts the .orig.cia files without rebuilding them into a .cia. Useful for manual updates. Run make afterwards to complete the build.

`make tidy`: Removes any built `.cia`, `.cxi`, or `cfa` files in the poke-cia repo.

`make repotidy`: Performs the same function as `make tidy` above, but also instructs the rom's repo to run its version of `make tidy`.

`make clean`: Performs the same function as `make tidy`, but also deletes the extracted rom directories in the poke-cia repo.

`make repoclean`: Performs the same function as `make clean` above, but also instructs the rom's repo to run its own version of `make clean`. 

### MBC30 Patching

For ROM hacks that necessitate 4MB MBC30 ROM support:

- **Configuration**: Utilize the `build_mbc30` option. 
  - **Default Setting**: `false`.
  - **Action When Enabled**: Upon activation, the script `mbc30patch.py` is triggered post the extraction of `.orig.cia` files. This script modifies the `code.bin` to permit MBC30 ROMs to accommodate `$ff` banks, as opposed to the standard `$7f`. However, this change is conditional: the `code.bin` must correspond to the hash of an authentic `.cia` `code.bin`.
  
- **Supported Versions**: Currently, the supported `code.bin` files are based on specific original `.cia` versions. As we identify the correct addresses for patching, more versions will be incorporated.
  - `Pokémon Crystal (CTR-N-QBRA) (UE) (v0.1.0)`:
    - Hash: `d48acf4c062884c9ef6b546c573db2125f5f9253`

## Special Credits

I would like to give special credits to the following:

* [@mid-kid](https://github.com/mid-kid) originally came up with the idea of this tool, and this extension is developed based on his original repo.
* [@ISSOtm](https://github.com/ISSOtm) contributed significantly by restructuring the extension and preparing it for release.
* [@jakcron](https://github.com/jakcron) went above and beyond by troubleshooting our repository to address a bug in the prerequisite tool, ctrtool.
