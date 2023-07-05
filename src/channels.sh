#!/usr/bin/env bash

# This script manages all channels


# Listen on port 4097
# (This is how we communicate with the server)
coproc nc -l -k localhost 4097

# Channels
declare -A channels

# Last used channel ID
lastChanId=0

# Read commands from stdin
while IFS='$\n' read -r line; do
  read -r cmd args <<< "$line"

  case "$cmd" in
    list)
      echo "${!channels[@]}"
      ;;

    get)
      echo "${channels[$args]}"
      ;;

    open)
      chanId="$((lastChanId + 1))"
      lastChanId="$chanId"
      channels["$chanId"]="$args"
      echo "$chanId"
      ;;

    close)
      unset channels["$args"]
      echo "ok"
      ;;

    quit)
      break
      ;;

    *)
      if [ -n "$cmd" ]; then
        echo "unknown-command $cmd"
      else
        echo
      fi
      ;;
  esac
done <&"${COPROC[0]}" >&"${COPROC[1]}"

kill "$COPROC_PID"
