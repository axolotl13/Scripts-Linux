#!/bin/bash

string=$1
extension=(.py .sh .conf .js .yml .go .md .xml .css .html .php .cmake .cpp .java .sql .json)
dir=(/home /tmp)
exclude=(-E .icons -E .java -E .cache -E .mozilla -E .git -E .vscode -E phyton3.9 -E pytthon3.8 -E node_modules -E .gem -E cache -E Cache)

for i in $(seq 0 ${#string}); do
  array["$i"]=${string:$i:1}
  if [ "${array[$i]}" = "." ]; then
    if [[ "${extension[@]}" =~ "$1" ]]; then
      fd . "${dir[@]}" "${exclude[@]}" -He "$1" | fzf --preview "bat --style=numbers --color=always --line-range :500 {}"
      break
    else
      fd . "${dir[@]}" -e "$1" "${exclude[@]}"
      break
    fi
  else
    fd -Htf -td "$1" . "${dir[@]}" "${exclude[@]}"
    break
  fi
done
