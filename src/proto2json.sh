#!/usr/bin/env bash

proto=`cat`

json='{'

for token in $proto; do
  if [[ "$token" =~ ([a-zA-Z]+): ]]; then
    json="$json\"${BASH_REMATCH[1]}\":"
    continue
  fi

  case "$token" in 
    '{')
      json="$json:{"
      ;;
    '}')
      json="$json},"
      ;;
    ':')
      json="$json:"
      ;;
    \"*\")
      json="$json$token"
      ;;
    *)
      json="$json\"$token\""
      ;;
  esac
done

json="$json}"

# Remove trailing comma
json=`sed -e 's/,}$/}/' <<< "$json"`

# Output JSON
echo "$json"
#| jq -cM .

# Piping through jq ensures that we're outputting valid JSON
