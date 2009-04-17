#!/bin/sh

# Finds files, gives you the option to play one. Props to Steve for this
foo="fish"
COUNT=`find . -type f | wc -l`
while [ "x$foo" != "xy" ]; do
  echo "Choosing from $COUNT recordings..." >&2
  name=$(find . -type f | head -n $(($RANDOM % $COUNT)) | tail -n1)
  echo $name
  read foo
done
mplayer -cache 64000 "$name"

