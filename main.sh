#!/bin/bash

if ! command -v protoc &> /dev/null
then
  echo "protoc not found, please download from https://github.com/protocolbuffers/protobuf/releases/" 1>&2
  exit 1
fi

export proto="proto/goval.proto"
export proto_client="proto/client.proto"

if [ ! -f "$proto" ] || [ ! -f "$proto_client" ]; then
  echo "Missing protobuf files, please download them from https://govaldocs.pages.dev/api.proto and https://raw.githubusercontent.com/replit/protocol/master/client.proto" 1>&2
  exit 1
fi

websocketd-node --port 4096 --base64 ./src/bashval.sh
