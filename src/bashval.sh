#!/usr/bin/env bash

# TODO:
# Make encode an alias for ./src/utils/encode.sh

decode() {
  {
    IFS=$'\n' read -r -d '' CAPTURED_STDERR;
    IFS=$'\n' read -r -d '' CAPTURED_STDOUT;
  } < <((printf '\0%s\0' "$(base64 -d | protoc --decode="${1:-goval.Command}" "$proto")" 1>&2) 2>&1)

  if [ -n "$CAPTURED_STDERR" ]; then
    echo -n $'[BASHVAL]\t' 1>&2
    echo "decode(): $CAPTURED_STDERR" 1>&2
    return 1
  fi

  echo -n "$CAPTURED_STDOUT"
}

toast() {
  ./src/utils/encode.sh <<- EOM
channel: 0
toast {
  text: "$@"
}
EOM
}

# Initial ready message
./src/utils/encode.sh <<- EOM
containerState {
  state: READY
}
EOM

# Connection toast
toast "Welcome to Bashval"
echo -n $'[BASHVAL]\t' 1>&2
echo "Someone connected" 1>&2

# Logs file
logs="bashval.log"
echo -n "" > "$logs"

# Channels
declare -A channels

# Last used channel ID
lastChanId=0

while IFS='$\n' read -r line; do
  msgProto=$(decode <<< "$line")
  msg=$(./src/proto2json.sh <<< "$msgProto" 2>/dev/null)

  echo "$msgProto" >> "$logs"

  if [ "$?" -ne 0 ]; then
    echo "Failed to decode message:" 1>&2
    echo "$msgProto" 1>&2
    echo $'\n\n\n' >> "$logs"
    continue
  fi

  echo "$msg" >> "$logs"
  echo $'\n\n\n' >> "$logs"

  # Message ref
  ref=$(jq -Mr .ref <<< "$msg")

  # Message channel
  chan="$(jq -Mr .channel <<< "$msg")"
  if [ "$chan" = "null" ] || [ -z "$chan" ]; then
    chan="0"
  fi

  # Do something with the message
  if [ "$chan" = "0" ]; then
    if [ ! "$(jq -M .ping <<< "$msg")" = "null" ]; then
      ./src/utils/encode.sh <<- EOM
channel: 0
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
      echo -n $'[CHAN0]\t\t' 1>&2
      echo -n "Opening channel $chanId" 1>&2
      echo -n $'\t' 1>&2
      echo "with service $service" 1>&2

      # Increment the last used channel ID
      lastChanId="$chanId"

      # Save channel
      channels["$chanId"]="$(jq -Mrc .openChan <<< "$msg")"

      # Send response
      ./src/utils/encode.sh <<- EOM
channel: 0
session: 1
openChanRes {
  id: $chanId
}
ref: "$ref"
EOM
    fi
  else
    # Get channel
    channel="${channels[$chan]}"

    if [ -z "$channel" ]; then
      # Channel not found

      # TODO: handle this

      :
    else
      # Get service
      service="$(jq -Mrc .service <<< "$channel")"

      # Service script
      serviceScript="./src/services/$service.sh"

      if [ -f "$serviceScript" ]; then
        # Call service
        "$serviceScript" "$ref" "$chan" "$channel" "$msg"
      else
        # Service not implemented
        :
      fi
    fi
  fi
done
