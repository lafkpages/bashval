#!/bin/bash

proto="api.proto"

protoc --decode="$proto" "$proto" < test/demo_message.bin
