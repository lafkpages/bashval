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

proto="api.proto"

while IFS='$\n' read -r line; do
  protoc --decode=api.Command "$proto" <<< "$line"
done
