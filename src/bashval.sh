#!/usr/bin/env bash

encode() {
  protoc --encode="${1:-goval.Command}" "$proto" | base64
}

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

# Import services
for service in src/services/*.sh; do
  source "$service"
done

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
  _chan="$(jq -Mr .channel <<< "$msg")"
  chan="${_chan:-0}"

  # Do something with the message
  if [ "$chan" = "0" ]; then
    chan0 "$ref" <<< "$msg"
    continue
  fi
done
