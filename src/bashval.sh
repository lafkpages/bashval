#!/bin/bash

if ! command -v protoc &> /dev/null
then
  echo "protoc not found, please download from https://github.com/protocolbuffers/protobuf/releases/" 1>&2
  exit 1
fi

encode() {
  protoc --encode="${1:-goval.Command}" "$proto"
}

decode() {
  protoc --decode="${1:-goval.Command}" "$proto"
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

# Logs file
logs="bashval.log"
echo -n "" > "$logs"

while IFS='$\n' read -r line; do
  decode <<< "$line" >> "$logs"
done
