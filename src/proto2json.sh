#!/usr/bin/env bash

# TODO: this is dumb.
# Just use a normal Protobuf transformer like https://github.com/iamazeem/proto-convert

json='{'

isInString=0
shouldSkipNlComma=0

currentToken=""

while IFS="" read -n1 char; do
  if [ "$isInString" = 1 ]; then
    currentToken="$currentToken$char"

    if [ "$char" = '"' ]; then
      isInString=0
    fi

    continue
  fi

  if [ "$char" = " " ]; then
    continue
  fi

  if [ "$char" = "" ]; then
    if [ "$shouldSkipNlComma" = 1 ]; then
      json="$json$currentToken"
      shouldSkipNlComma=0
    else
      json="$json$currentToken,"
    fi
    currentToken=""
  fi

  if [ "$char" = ':' ]; then
    json="$json\"$currentToken\":"
    currentToken=""
    continue
  fi

  if [ "$char" = "{" ]; then
    json="$json\"$currentToken\":{"
    currentToken=""
    shouldSkipNlComma=1
    continue
  fi

  if [ "$char" = "}" ]; then
    json="${json%,}}"
    currentToken=""
    continue
  fi

  currentToken="$currentToken$char"
done

echo "${json%,}}" | jq -Mnc --stream -f src/utils/dupekeys.jq
