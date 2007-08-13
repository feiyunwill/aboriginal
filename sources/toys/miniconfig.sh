#!/bin/bash

# miniconfig.sh copyright 2005 by Rob Landley <rob@landley.net>
# Licensed under the GNU General Public License version 2.

# Run this in the linux kernel build directory with a starting file, and
# it creates a file called mini.config with all the redundant lines of that
# .config removed.  The starting file must match what the kernel outputs.
# If it doesn't, then run "make oldconfig" on it to get one that does.

export KCONFIG_NOTIMESTAMP=1

if [ $# -ne 1 ] || [ ! -f "$1" ]
then
  echo "Usage: miniconfig.sh configfile" 
  exit 1
fi

if [ "$1" == ".config" ]
then
  echo "It overwrites .config, rename it and try again."
  exit 1
fi

make allnoconfig KCONFIG_ALLCONFIG="$1" > /dev/null
if ! cmp .config "$1"
then
  echo Sanity test failed, normalizing starting configuration...
  diff -u "$1" .config
fi
cp .config .big.config
cp .config mini.config

echo "Calculating mini.config..."

LENGTH=`cat $1 | wc -l`

# Loop through all lines in the file 
I=1
while true
do
  if [ $I -gt $LENGTH ]
  then
    break
  fi
  sed -n "${I}!p" mini.config > .config.test
  # Do a config with this file
  make allnoconfig KCONFIG_ALLCONFIG=.config.test > /dev/null

  # Compare.  Because we normalized at the start, the files should be identical.
  if cmp -s .config .big.config
  then
    mv .config.test mini.config
    LENGTH=$[$LENGTH-1]
  else
    I=$[$I + 1]
  fi
  echo -n -e "\r$[$I-1]/$LENGTH lines $(cat mini.config | wc -c) bytes   "
done
rm .big.config
echo
