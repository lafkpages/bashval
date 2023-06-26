#!/bin/bash

proto="api.proto"

protoc --decode=api.Command "$proto" < test/demo_message.bin
