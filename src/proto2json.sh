#!/usr/bin/env bash

# TODO: this is dumb.
# Just use a normal Protobuf transformer like https://github.com/iamazeem/proto-convert

proto=$(cat)

json='{'

isInProp=0

for token in $proto; do
  if [[ "$token" =~ ([a-zA-Z]+): ]]; then
    json="$json\"${BASH_REMATCH[1]}\":"
    isInProp=1
    continue
  fi

  case "$token" in
  '{')
    json="$json:{"
    ;;
  '}')
    json="${json%,}},"
    ;;
  ':')
    json="$json:"
    ;;
  \"*\")
    json="$json$token"
    if [ "$isInProp" -eq 1 ]; then
      json="$json,"
      isInProp=0
    fi
    ;;
  *)
    json="$json\"$token\""
    if [ "$isInProp" -eq 1 ]; then
      json="$json,"
      isInProp=0
    fi
    ;;
  esac
done

echo "${json%,}}" | jq -Mnc --stream -f src/utils/dupekeys.jq
