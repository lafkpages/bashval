#!/usr/bin/env bash

# Exec
# A simple service for executing shell commands, one at a time.

ref="$1"
chan="$2"
channel="$3"
msg="$4"

# Logs
echo -n $'[EXEC]\t' 1>&2
echo "Execing something..." 1>&2

# Send state message
./src/utils/encode.sh <<- EOM
channel: $chan
state: Running
EOM

# Exec args
readarray -t args < <(jq -Mc '.exec.args[]' <<< "$msg")

# Logs
echo $'[EXEC]\tRunning command\t' "${args[0]}" 1>&2

# Run the command, capturing stdout and stderr
{
    IFS=$'\n' read -r -d '' stderr;
    IFS=$'\n' read -r -d '' stdout;
} < <((printf '\0%s\0' "$(${args[@]})" 1>&2) 2>&1)

# Turn into JSON
stderrJson=$(jq -MRc <<< "$stderr")
stdoutJson=$(jq -MRc <<< "$stdout")

# Send stdout
./src/utils/encode.sh <<- EOM
channel: $chan
output: $stdoutJson
EOM

# Send stderr
./src/utils/encode.sh <<- EOM
channel: $chan
error: $stderrJson
EOM

# Send state message
./src/utils/encode.sh <<- EOM
channel: $chan
state: Stopped
EOM

# Send ok
./src/utils/encode.sh <<- EOM
ref: "$ref"
channel: $chan
ok: {}
EOM

# TODO: export .exec.env to subshell
