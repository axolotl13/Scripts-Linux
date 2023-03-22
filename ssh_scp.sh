#!/bin/bash

source ./.env

user=$USER
ip=$HOSTNAME
default="$HOME/Docker/"

ping -c 3 $ip
if [ "$?" = 0 ]; then
  if [ "$1" != "" ]; then
    if [ "$2" != "" ]; then
      scp "$1" $user@$ip:"$2"
      echo "Se completo la transferencia"
    else
      scp "$1" $user@$ip:"$default"
      echo "Se completo la transferencia"
    fi
  else
    echo "Necesitas al menos un argumento"
  fi
else
  echo "IP $ip no encontrada"
fi
