# FFiller
Creates and rewrites files of arbitrary size.

### Installation
    wget -qO- https://raw.githubusercontent.com/backer-and/FFiller/master/install.sh | bash

Or just run it from where it is with ./ffiller.sh

Same applies for `uninstall.sh`

### Usage
    ffiller [-f <file>] -s <size> [-t zero/random] -v -y [<file> <file2> ...]

**The file size argument is mandatory.**

    --file: [-f <file>]         With -f option, all filenames at the end will be ignored.
                                Default name: 'out'.


    --size: -s <size>           The file size argument is mandatory and can be expressed in K, M or G.

                                ffiller -s 10M


    --type: [-t zero/random]    The file can be filled with '/dev/zero' or '/dev/urandom'.
                                Default: empty file.

                                ffiller -f file -s 10M -t random


    --verbose: -v               Display transfer stats.

    --yall: -y                  Skips all rewriting confirmations.

    --version                   Display version.

### Examples

    ffiller -f file -s 10K -t zero
creates or fills up the _file_ from /dev/zero, skipping any other file at the end


    ffiller -s 10M -t random file1 file2 file3
creates or fills up last tree files from /dev/urandom

### Output
The output produced is a file re/filled based on the option _type_.
