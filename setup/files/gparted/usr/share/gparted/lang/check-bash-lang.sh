#!/bin/bash
# A script to check if the variables are OK for bash shell script.
if [ -z "$(echo "$LANG" | grep -iE "(UTF-8|utf8)")" ]; then
  echo "This program must be run in UTF-8 environment!"
  echo "Now the environment variable LANG is: $LANG"
  echo "Program terminated!"
  exit 1
fi
prog="$(basename $0)"
for i in ./*; do
  nm="$(basename $i)"
  [ "$nm" = "$prog" ] && continue
  # BIG5 is the only exception. Skip it.
  [ -n "$(echo $nm | grep -i big5)" ] && continue
  # skip dir
  [ -d "$nm" ] && continue
  echo "Checking $nm..."
  . $nm
done
