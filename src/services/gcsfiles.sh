#!/usr/bin/env bash

# GCSFiles
# Simple service for reading and writing to files

# Read directory
readdir=$(jq -Mrc .readdir <<<"$msg")

# Read file
readfile=$(jq -Mrc .read <<<"$msg")

# Write file
writefile=$(jq -Mrc .write <<<"$msg")

# Stat file
statfile=$(jq -Mrc .stat <<<"$msg")

if [ ! "$readdir" = "null" ]; then
  pathRaw=$(jq -Mc .readdir.path <<<"$msg")

  if [ "$pathRaw" = "null" ] || [ -z "$pathRaw" ]; then
    # No path specified
    echo -n $'[GCSFILES]\tNo path specified\t\n[GCSFILES]\t' 1>&2
    echo "$msg" 1>&2
    encode <<-EOM
ref: "$ref"
channel: $chan
error: "No path specified"
EOM
    exit 1
  fi

  path=$(jq -Mrc <<<"$pathRaw")

  echo -n $'[GCSFILES]\tReading directory\t' 1>&2
  echo "$path" 1>&2

  files=$(ls -la "$path" | tail -n +4 | jq -MRc '{
    type: (
      match("^(.)").captures[0].string
    ),
    path: (
      match("^.+\\d (.+)$").captures[0].string
    )
  }' | jq -Mrcs '.' |
    hjson -omitRootBraces -quoteAlways |
    sed -e 's/type: "d"/type: DIRECTORY/' \
      -e 's/type: "."//' -e '1d' \
      -e '$d' -e 's/^  {/  files {/')

  encode <<-EOM
ref: "$ref"
channel: $chan
files {
  $files
}
EOM
elif [ ! "$statfile" = "null" ]; then
  pathRaw=$(jq -Mc .path <<<"$statfile")

  if [ "$pathRaw" = "null" ] || [ -z "$pathRaw" ]; then
    # No path specified
    echo -n $'[GCSFILES]\tNo path specified\t\n[GCSFILES]\t' 1>&2
    echo "$msg" 1>&2
    encode <<-EOM
ref: "$ref"
channel: $chan
error: "No path specified"
EOM
    exit 1
  fi

  path=$(jq -Mrc <<<"$pathRaw")

  echo -n $'[GCSFILES]\tStatting file\t\t' 1>&2
  echo "$path" 1>&2

  # Stat file
  stat=$(stat "$path" 2>/dev/null)
  statCode="$?"

  if [ "$statCode" = "0" ]; then
    read -r modTime fileMode size extra <<<$(echo "$stat" | awk '{ print $1 " " $3 " " $8 }')

    # Send response
    encode <<-EOM
channel: $chan
statRes {
  exists: true
  size: $size
  fileMode: "$fileMode"
  modTime: $modTime
}
ref: "$ref"
EOM

    # Logs
    echo -n $'[GCSFILES]\tFile found\t\t' 1>&2
    echo "$path" 1>&2
  else
    # File not found
    encode <<-EOM
ref: "$ref"
channel: $chan
statRes {
  exists: false
}
EOM

    # Logs
    echo -n $'[GCSFILES]\tFile not found\t\t' 1>&2
    echo "$path" 1>&2
  fi

elif [ ! "$readfile" = "null" ]; then
  pathRaw=$(jq -Mc .path <<<"$readfile")

  if [ "$pathRaw" = "null" ] || [ -z "$pathRaw" ]; then
    # No path specified
    echo -n $'[GCSFILES]\tNo path specified\t\n[GCSFILES]\t' 1>&2
    echo "$msg" 1>&2
    encode <<-EOM
ref: "$ref"
channel: $chan
error: "No path specified"
EOM
    exit 1
  fi

  path=$(jq -Mrc <<<"$pathRaw")

  # Goval ident protocol
  if [ "$path" = ".config/goval/info" ]; then
    path="src/utils/goval-ident.json"

    echo $'[GCSFILES]\tGoval Ident requested' 1>&2
  else
    echo -n $'[GCSFILES]\tReading file\t\t' 1>&2
    echo "$path" 1>&2
  fi

  # Read file
  file=$(base64 "$path" 2>/dev/null)
  fileCode="$?"

  if [ "$fileCode" = "0" ]; then
    # Send response
    encode <<-EOM
ref: "$ref"
channel: $chan
file {
  content: "$file"
}
EOM
  else
    # File not found
    encode <<-EOM
ref: "$ref"
channel: $chan
error: "File not found"
EOM
    exit 1
  fi
fi
