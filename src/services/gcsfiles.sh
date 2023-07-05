#!/usr/bin/env bash

# GCSFiles
# Simple service for reading and writing to files

ref="$1"
chan="$2"
channel="$3"
msg="$4"

# Read directory
readdir=$(jq -Mrc .readdir <<< "$msg")

# Read file
readfile=$(jq -Mrc .read <<< "$msg")

# Write file
writefile=$(jq -Mrc .write <<< "$msg")

if [ -n "$readdir" ]; then
  path=$(jq -Mrc .readdir.path <<< "$msg")

  files=$(ls -la "$path" | tail -n +4 | jq -MRc '{
    type: (
      match("^(.)").captures[0].string
    ),
    name: (
      match("^.+\\d (.+)$").captures[0].string
    )
  }' | jq -Mrcs '.' | \
  hjson -omitRootBraces -quoteAlways | \
  sed -e 's/type: "d"/type: DIRECTORY/' \
    -e 's/type: "."/type: FILE/' -e '1d' -e '$d')

  ./src/utils/encode.sh <<- EOM
ref: "$ref"
channel: "$chan"
files {
  files {
    $files
  }
}
EOM
fi
