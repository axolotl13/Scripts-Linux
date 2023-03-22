#!/usr/bin/env bash

nvr="$HOME/.local/bin/nvr"
files=()
total=0
lastsession=$(find /tmp/nvim* -type s -printf "%T@ %p\n" 2>/dev/null | sort -n | cut -d' ' -f 2 | tail -n 10)

if [[ -z "${lastsession}" ]]; then
  nvim "$@"
else
  for i in $lastsession; do
    if [[ $i != '/tmp/nvimsocket' ]]; then
      files["$total"]="$i"
      total+=1
    fi
  done
  addres=${files[0]}
  $nvr --servername "$addres" "$@"
fi
