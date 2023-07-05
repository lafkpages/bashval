#!/usr/bin/env bash

# Encodes a protobuf message from stdin
# into binary, and then base64

protoc --encode="${1:-goval.Command}" "$proto" | base64
