#!/bin/bash

if ! command -v protoc &> /dev/null
then
  echo "protoc not found, please download from https://github.com/protocolbuffers/protobuf/releases/" 1>&2
  exit 1
fi

if [ ! -f "api.proto" ]; then
  echo "Missing protobuf files, please download them from https://govaldocs.pages.dev/api.proto" 1>&2
  exit 1
fi

proto="proto/api.proto"

encode() {
  protoc --encode=api.Command "$proto"
}

decode() {
  protoc --decode=api.Command "$proto"
}

# Initial ready message
encode <<- EOM
containerState {
  state: READY
}
EOM

while IFS='$\n' read -r line; do
  decode "$line"
done
