#!/usr/bin/env bash

# Ensure protoc is installed
if ! command -v protoc &> /dev/null
then
  echo "protoc not found, please download from https://github.com/protocolbuffers/protobuf/releases/" 1>&2
  exit 1
fi

# Path to protobuf files
export proto="proto/goval.proto"
export proto_client="proto/client.proto"

# Ensure protobuf files exist
if [ ! -f "$proto" ] || [ ! -f "$proto_client" ]; then
  echo "Missing protobuf files, please download them from https://govaldocs.pages.dev/api.proto and https://raw.githubusercontent.com/replit/protocol/master/client.proto" 1>&2
  exit 1
fi

# Log a newline after WebSocket server starts,
# for prettier logs
{
  sleep 0.5
  echo
} &

# Start WebSocket server
websocketd-node --port 4096 --base64 ./src/bashval.sh
