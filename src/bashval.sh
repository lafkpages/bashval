#!/usr/bin/env bash

alias encode='./src/utils/encode.sh'

decode() {
  base64 -d | protoc --decode="${1:-goval.Command}" "$proto"
}

toast() {
  encode <<- EOM
channel: 0
toast {
  text: "$@"
}
EOM
}

# Initial ready message
encode <<- EOM
containerState {
  state: READY
}
EOM

# Connection toast
toast "Welcome to Bashval"
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
  else
    # Get channel
    channel="${channels[$chan]}"

    if [ -z "$channel" ]; then
      # Channel not found

      # TODO: handle this
    else
      # Get service
      service="$(jq -Mrc .service <<< "$channel")"

      # Call service
      "./src/services/$service.sh" "$ref" "$chan" "$channel" <<< "$msg"
    fi
  fi
done
