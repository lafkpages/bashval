#!/bin/bash

export proto="proto/api.proto"
export proto_client="proto/client.proto"

if [ ! -f "$proto" ] || [ ! -f "$proto_client" ]; then
  echo "Missing protobuf files, please download them from https://govaldocs.pages.dev/api.proto and https://raw.githubusercontent.com/replit/protocol/master/client.proto" 1>&2
  exit 1
fi

websocketd --port=4096 --devconsole -binary --passenv proto,proto_client ./src/bashval.sh
