#!/bin/bash

if [ ! -f "api.proto" ]; then
  echo "Missing protobuf files, please download them from https://govaldocs.pages.dev/api.proto" 1>&2
  exit 1
fi
