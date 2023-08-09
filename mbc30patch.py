# poke-cia mbc30patch.py
# This file is part of the poke-cia project, which provides tools
# for repackaging Nintendo 3DS Virtual Console (VC) .cia files 
# using built .gbc(s) and .patch(s) from the pret Pokémon Gen I/II repos.
# This specific script is used to patch code.bin files.
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

import hashlib
import os

def compute_sha1(file_path):
    with open(file_path, "rb") as f:
        file_data = f.read()
        return hashlib.sha1(file_data).hexdigest()

def check_and_modify(file_path, address, original_value, new_value, cia_name):
    with open(file_path, "rb+") as f:
        f.seek(address)
        current_value = f.read(1)[0]
        if current_value == original_value:
            f.seek(address)
            f.write(bytes([new_value]))
            print(f"Matching code.bin found in '{file_path}' for original '{cia_name}'. Modified hexadecimal address {hex(address)} from {hex(original_value)} to {hex(new_value)}.")
        else:
            print(f"Unexpected value at address {hex(address)} in '{file_path}' for original '{cia_name}'. Expected {hex(original_value)} but found {hex(current_value)}.")

def main():
    # Table for hash values, addresses, original values, new values, and CIA name
    modifications_table = [
        {
            'hash': 'd48acf4c062884c9ef6b546c573db2125f5f9253', 
            'address': 0xaa488, 
            'original_value': 0x7f, 
            'new_value': 0xff,
            'cia_name': 'Pokémon Crystal (CTR-N-QBRA) (UE) (v0.1.0)'
        },
        # Add more entries as needed for different versions
    ]

    for dir_name in os.listdir():
        if os.path.isdir(dir_name) and 'exefs' in os.listdir(dir_name):
            target_file = os.path.join(dir_name, 'exefs', 'code.bin')
            if os.path.exists(target_file):
                file_hash = compute_sha1(target_file)

                for entry in modifications_table:
                    if file_hash == entry['hash']:
                        check_and_modify(target_file, entry['address'], entry['original_value'], entry['new_value'], entry['cia_name'])

if __name__ == "__main__":
    main()

