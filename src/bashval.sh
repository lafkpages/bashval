#!/bin/bash

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
