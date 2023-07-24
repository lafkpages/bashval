#!/usr/bin/env bash

# Example usage:
#
# ./test/dups.sh < test/demo_exec_message_conv.json

jq -Mnc --stream -f src/utils/dupekeys.jq
