#!/usr/bin/env sh

set -e

# Download V
if [ ! -e 'v/' ]
then
	git clone https://github.com/vlang/v
fi

cd v
if [ ! -e './v' ]
then
	make
fi
sudo ./v symlink
cd ..
