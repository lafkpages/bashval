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

# Stat file
statfile=$(jq -Mrc .stat <<< "$msg")

if [ ! "$readdir" = "null" ]; then
  pathRaw=$(jq -Mc .readdir.path <<< "$msg")

  if [ "$pathRaw" = "null" ] || [ -z "$pathRaw" ]; then
    # No path specified
    echo -n $'[GCSFILES]\tNo path specified\t\n[GCSFILES]\t' 1>&2
    echo "$msg" 1>&2
    ./src/utils/encode.sh <<- EOM
ref: "$ref"
channel: $chan
error: "No path specified"
EOM
    exit 1
  fi

  path=$(jq -Mrc <<< "$pathRaw")

  echo -n $'[GCSFILES]\tReading directory\t' 1>&2
  echo "$path" 1>&2

  files=$(ls -la "$path" | tail -n +4 | jq -MRc '{
    type: (
      match("^(.)").captures[0].string
    ),
    path: (
      match("^.+\\d (.+)$").captures[0].string
    )
  }' | jq -Mrcs '.' | \
  hjson -omitRootBraces -quoteAlways | \
  sed -e 's/type: "d"/type: DIRECTORY/' \
    -e 's/type: "."//' -e '1d' \
    -e '$d' -e 's/^  {/  files {/')

  ./src/utils/encode.sh <<- EOM
ref: "$ref"
channel: $chan
files {
  $files
}
EOM
elif [ ! "$statfile" = "null" ]; then
  pathRaw=$(jq -Mc .path <<< "$statfile")

  if [ "$pathRaw" = "null" ] || [ -z "$pathRaw" ]; then
    # No path specified
    echo -n $'[GCSFILES]\tNo path specified\t\n[GCSFILES]\t' 1>&2
    echo "$msg" 1>&2
    ./src/utils/encode.sh <<- EOM
ref: "$ref"
channel: $chan
error: "No path specified"
EOM
    exit 1
  fi

  path=$(jq -Mrc <<< "$pathRaw")

  echo -n $'[GCSFILES]\tStatting file\t' 1>&2
  echo "$path" 1>&2

  # Stat file
  stat=$(stat "$path" 2>/dev/null)
  statCode="$?"

  if [ "$statCode" = "0" ]; then
    echo -n "$stat" | awk '{ print $1 " " $3 " " $8 }' | read -r modTime fileMode size

    # Send response
    ./src/utils/encode.sh <<- EOM
ref: "$ref"
channel: $chan
statRes {
  exists: true
  modTime: $modTime
  fileMode: "$fileMode"
  size: $size
}
EOM
  else
    # File not found
    ./src/utils/encode.sh <<- EOM
ref: "$ref"
channel: $chan
statRes {
  exists: false
}
EOM
  fi
fi
