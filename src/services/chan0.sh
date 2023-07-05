#!/usr/bin/env bash

chan0 () {
  msg="$(cat)"
  ref="$1"

  if [ ! "$(jq -M .ping <<< "$msg")" = "null" ]; then
    encode <<- EOM
pong {}
ref: "$ref"
EOM
  elif [ ! "$(jq -M .openChan <<< "$msg")" = "null" ]; then
    # Get channel service
    service="$(jq -Mrc .openChan.service <<< "$msg")"

    # Find next available channel ID
    # (lastChanId plus one)
    chanId="$((lastChanId + 1))"

    # Logs
    echo -n "Opening channel $chanId" 1>&2
    echo -n $'\t' 1>&2
    echo "with service $service" 1>&2

    # Increment the last used channel ID
    lastChanId="$chanId"

    # Save channel
    channels["$chanId"]="$(jq -Mrc .openChan <<< "$msg")"

    # Send response
    encode <<- EOM
session: 1
openChanRes {
  id: $chanId
}
ref: "$ref"
EOM
  fi
}
