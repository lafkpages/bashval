#!/usr/bin/env bash

# Load the encode util function
source ./src/utils/encode.sh

decode() {
  # Decode from base64, then from protobuf
  {
    IFS=$'\n' read -r -d '' CAPTURED_STDERR
    IFS=$'\n' read -r -d '' CAPTURED_STDOUT
  } < <((printf '\0%s\0' "$(base64 -d | protoc --decode="${1:-goval.Command}" "$proto")" 1>&2) 2>&1)

  # Log errors
  if [ -n "$CAPTURED_STDERR" ]; then
    echo -n $'[BASHVAL]\t' 1>&2
    echo "decode(): $CAPTURED_STDERR" 1>&2
    return 1
  fi

  # Return decoded message
  echo -n "$CAPTURED_STDOUT"
}

toast() {
  # Encode message into JSON
  msg=$(jq -MRc <<<"$@")

  # Shows a toast in the IDE
  encode <<-EOM
channel: 0
toast {
  text: $msg
}
EOM
}

# Get a channel by ID
getChannel() {
  chanId="$1"

  # Send get command
  nc localhost 4097 <<-EOM
get $chanId

EOM

  # Read response
  nc localhost 4097 </dev/null
}

# Open a channel
openChannel() {
  # Channel data (.openChan)
  channel="$1"

  # Send open command
  nc localhost 4097 <<-EOM
open $channel

EOM

  # Read response
  nc localhost 4097 </dev/null
}

# Close a channel by ID
closeChannel() {
  # Channel ID
  chanId="$1"

  # Send close command
  nc localhost 4097 <<-EOM
close $chanId

EOM

  # Read response
  nc localhost 4097 </dev/null
}

# List channels
listChannels() {
  # Send list command
  nc localhost 4097 <<-EOM
list

EOM

  # Read response
  nc localhost 4097 </dev/null
}

# Initial ready message
encode <<-EOM
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
echo -n "" >"$logs"

# Main loop, one iteration per WS message
while IFS='$\n' read -r line; do
  msgProto=$(decode <<<"$line")
  msg=$(./src/proto2json.sh <<<"$msgProto" 2>/dev/null)

  decodeStatus="$?"

  echo "$msgProto" >>"$logs"

  if [ "$decodeStatus" -ne 0 ]; then
    echo $'[BASHVAL]\t'"Failed to decode message:" 1>&2
    echo $'[BASHVAL]\t'"$msgProto" 1>&2
    echo $'\n\n\n' >>"$logs"
    continue
  fi

  echo "$msg" >>"$logs"
  echo $'\n\n\n' >>"$logs"

  # Message ref
  ref=$(jq -Mr .ref <<<"$msg")

  # Message channel
  chan="$(jq -Mr .channel <<<"$msg")"
  if [ "$chan" = "null" ] || [ -z "$chan" ]; then
    chan="0"
  fi

  # Do something with the message
  if [ "$chan" = "0" ]; then
    if [ ! "$(jq -M .ping <<<"$msg")" = "null" ]; then
      encode <<-EOM
channel: 0
pong {}
ref: "$ref"
EOM
    elif [ ! "$(jq -M .openChan <<<"$msg")" = "null" ]; then
      # Get channel service
      service="$(jq -Mrc .openChan.service <<<"$msg")"

      # Open channel
      chanId=$(openChannel "$(jq -Mrc .openChan <<<"$msg")")

      # Logs
      echo -n $'[CHAN0]\t\t' 1>&2
      echo -n "Opened channel $chanId" 1>&2
      echo -n $'\t' 1>&2
      echo "with service $service" 1>&2

      # Send response
      encode <<-EOM
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
    channel="$(getChannel "$chan")"

    if [ -z "$channel" ]; then
      # Channel not found

      # TODO: handle this

      # Logs
      echo $'[CHAN'"$chan"$']\t\tChannel not found' 1>&2
    else
      # Get service
      service="$(jq -Mrc .service <<<"$channel")"

      # Service script
      serviceScript="./src/services/$service.sh"

      if [ -f "$serviceScript" ]; then
        # Logs
        echo $'[CHAN'"$chan"$']\t\t'"${service^^}" 1>&2

        # Call service
        "$serviceScript" "$ref" "$chan" "$channel" "$msg"
      else
        # Service not implemented
        echo $'[CHAN'"$chan"$']\t\t'"${service^^} not implemented" 1>&2
      fi
    fi
  fi
done

# Exit
echo $'[BASHVAL]\tExiting' 1>&2
