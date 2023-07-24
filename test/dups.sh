#!/usr/bin/env bash

jq -Mcn --stream 'def fromstream_with_dups(i; fix):
  foreach i as $i (
    [null, null];

    if ($i | length) == 2 then
      if ($i[0] | length) == 0 then .
      elif $i[0][-1]|type == "string" then
        [ ( .[0] | setpath($i[0]; getpath($i[0]) + [$i[1]]) ), .[1] ]
      else [ ( .[0] | setpath($i[0]; $i[1]) ), .[1] ]
      end
    elif ($i[0] | length) == 1 then [ null, .[0] ]
    else .
    end;

    if ($i | length) == 1 then
      if ($i[0] | length) == 1 then .[1] | fix
      else empty
      end
    elif ($i[0] | length) == 0 then $i[1]
    else empty
    end
  );
def fix:
  if type != "object" then .
  else
    reduce keys_unsorted[] as $key (.;
      if .[$key]|length == 1 then
        .[$key] |= .[0]
      else
        .
      end)
  end;
fromstream_with_dups(inputs; fix)'
