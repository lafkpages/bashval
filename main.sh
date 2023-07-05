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

# Channels server PID file
channels_pid_file="runtime/channels.pid"

# Kill old channels server
if [ -f "$channels_pid_file" ]; then
  kill "$(cat "$channels_pid_file")"
fi

# Start channels server
./src/channels.sh &
channels_pid="$!"
echo -n "$channels_pid" > "$channels_pid_file"

# Start WebSocket server
websocketd-node --port 4096 --base64 ./src/bashval.sh

# Kill channels server
kill "$channels_pid"
rm "$channels_pid_file"
