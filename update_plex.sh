#!/bin/bash

install_plex() {
  token=$1
  read -p "¿Desea instalar plex?: " -r res
  if [[ $res != "y" ]]; then
    echo "No se instalo archivo alguno"
  else
    echo "Instalando archivo... $token"
    sleep 3
    plex="plexmediaserver_${token}_armhf.deb"
    if [ -n "$(find "$plex")" ]; then
      echo "Instalando nueva versión"
      sudo dpkg -i "$plex"
      rm "$plex"
    else
      echo "Intenta de nuevo"
    fi
  fi
}

download_plex() {
  token=$1
  read -p "¿Desea descargar plex?: " -r res
  if [[ $res != "y" ]]; then
    echo "No se descargo archivo alguno"
    install_plex "$token"
  else
    echo "Descargando archivo..."
    sleep 3
    url="https://downloads.plex.tv/plex-media-server-new/${token}/debian/plexmediaserver_${token}_armhf.deb"
    wget -c "$url"
    install_plex "$token"
  fi
}

download_plex "1.18.5.2309-f5213a238"
