#!/usr/bin/env bash

json='{'

isInString=0
isAfterColon=0
shouldSkipNlComma=0

currentToken=""

while IFS="" read -n1 char; do
  if [ "$isInString" = 1 ]; then
    currentToken="$currentToken$char"

    if [ "$char" = '"' ]; then
      isInString=0
    fi
  elif [ "$char" = "\"" ]; then
    isInString=1
    currentToken="$currentToken$char"
  elif [ "$char" = " " ]; then
    :
  elif [ "$char" = "" ]; then
    if [ "$shouldSkipNlComma" = 1 ]; then
      json="$json$currentToken"
      shouldSkipNlComma=0
    else
      json="$json$currentToken,"
    fi
    currentToken=""
  elif [ "$char" = ':' ]; then
    json="$json\"$currentToken\":"
    currentToken=""
    isAfterColon=1
  elif [ "$char" = "{" ]; then
    json="$json\"$currentToken\":{"
    currentToken=""
    shouldSkipNlComma=1
  elif [ "$char" = "}" ]; then
    json="${json%,}}"
    currentToken=""
  else
    if [ "$isAfterColon" = 1 ]; then
      currentToken="$currentToken\"$char"
    else
      currentToken="$currentToken$char"
    fi
  fi

  if [ "$char" = ":" ] || [ "$char" = " " ]; then
    :
  else
    isAfterColon=0
  fi
done

json="${json%,}}"

jsonWithDupes=$(jq -Mnc --stream -f src/utils/dupekeys.jq <<<"$json")

if [ "$?" = 0 ]; then
  echo "$jsonWithDupes"
else
  echo "$json" 1>&2
  exit "$?"
fi
