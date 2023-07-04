#!/usr/bin/env bash

proto="proto/goval.proto"

protoc --decode=goval.Command "$proto" < test/demo_message.bin
