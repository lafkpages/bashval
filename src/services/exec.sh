#!/usr/bin/env bash

# Exec
# A simple service for executing shell commands, one at a time.

# Logs
echo -n $'[EXEC]\t\t' 1>&2
echo "Execing something..." 1>&2

# Send state message
encode <<-EOM
channel: $chan
state: Running
EOM

# Exec args
readarray -t args < <(jq -Mc '.exec.args[]' <<<"$msg")

# Logs
echo $'[EXEC]\t\tRunning command\t' "${args[0]}" 1>&2

# Run the command, capturing stdout and stderr
{
    IFS=$'\n' read -r -d '' stderr
    IFS=$'\n' read -r -d '' stdout
} < <((printf '\0%s\0' "$(${args[@]})" 1>&2) 2>&1)

# Turn into JSON
stderrJson=$(jq -MRc <<<"$stderr")
stdoutJson=$(jq -MRc <<<"$stdout")

# Send stdout
encode <<-EOM
channel: $chan
output: $stdoutJson
EOM

# Send stderr
encode <<-EOM
channel: $chan
error: $stderrJson
EOM

# Send state message
encode <<-EOM
channel: $chan
state: Stopped
EOM

# Send ok
encode <<-EOM
ref: "$ref"
channel: $chan
ok: {}
EOM

# TODO: export .exec.env to subshell
