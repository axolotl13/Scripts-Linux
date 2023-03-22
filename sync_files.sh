#!/bin/bash

# Pequeño script que sincronizan mis documentos de la thinkbook a la raspberry
source ./.env

sync_file() {
  local user=$USER
  local host=$HOSTNAME
  local port=$PORT
  local exclude="node_modules .git"

  # ping -c 3 $host
  # El $? captura el código de salida de un comando
  # if [[ $? != 0 ]]; then
  if [[ ! $(ping -c 3 $host) ]]; then
    echo "No se pudo completar la acción"
  else
    echo "Servidor encontrado"
    sleep 3
    for files in "$@"; do
      rsync -avzhPe "ssh -p $port" --exclude="$exclude" --delete --progress "$HOME/$files/" "$user@$host:/home/$user/$files"
      # De pi a thinkbook
      # rsync -avzh "ssh -p 39906" $user@$host:/home/$user/$files/ $HOME/$files
    done
  fi
}

sync_file Documentos Imágenes #Backups/Thinkpad Backups/Minecraft
