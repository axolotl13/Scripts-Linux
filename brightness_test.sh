#!/bin/bash

FILE="/sys/class/backlight/intel_backlight/brightness"

VALUE=(25 605 735 456 279 167 143 57 33)
NOW=$(date +"%H:%M")
# FILE="/tmp/test/1"
# SUDO=$(echo 130894 | sudo -S bash -c)

if [[ "$NOW" > "07:30" && "$NOW" < "10:59" ]]; then
  echo 130894 | sudo -S bash -c "echo ${VALUE[1]} > $FILE"
elif [[ "$NOW" > "10:58" && "$NOW" < "12:59" ]]; then
  echo 130894 | sudo -S bash -c "echo ${VALUE[2]} > $FILE"
elif [[ "$NOW" > "12:58" && "$NOW" < "15:59" ]]; then
  echo 130894 | sudo -S bash -c "echo ${VALUE[3]} > $FILE"
elif [[ "$NOW" > "15:58" && "$NOW" < "16:59" ]]; then
  echo 130894 | sudo -S bash -c "echo ${VALUE[4]} > $FILE"
elif [[ "$NOW" > "16:58" && "$NOW" < "17:59" ]]; then
  echo 130894 | sudo -S bash -c "echo ${VALUE[5]} > $FILE"
elif [[ "$NOW" > "17:58" && "$NOW" < "18:59" ]]; then
  echo 130894 | sudo -S bash -c "echo ${VALUE[6]} > $FILE"
elif [[ "$NOW" > "18:58" && "$NOW" < "19:59" ]]; then
  echo 130894 | sudo -S bash -c "echo ${VALUE[7]} > $FILE"
else
  echo 130894 | sudo -S bash -c "echo ${VALUE[8]} > $FILE"
fi
# (( NOW >= 7 && NOW <= 13 )) &&
# echo ok || echo no

TMP=/tmp/log
LOGFILE=$HOME/Escritorio/brightness2.log
FILE="/sys/class/backlight/intel_backlight/brightness"
sleep 6
RESULT=$(cat "$FILE")
AUX=$(cat "$TMP")
if (("$RESULT" == "$AUX")); then
  :
else
  LOGLINE="$(date +"%H:%M") $RESULT"
  echo "$RESULT" >"$TMP"
  echo "$LOGLINE" >>"$LOGFILE"
fi
