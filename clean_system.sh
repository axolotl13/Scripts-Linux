#!/bin/bash

# Pequeño script para limpiar los thumbnails que genera el administrador de archivos
# y los paquetes que se almacenan despues de instalar o actualizar en el sistema
clean_system() {
  yay -Scc --noconfirm
  journalctl --vaccum-time=15d
  for file in "$@"; do
    find "$HOME"/.cache/thumbnails/"$file" -name "*" -exec rm {} \;
  done
}

if [[ "$(ping -c 3 google.com)" ]]; then
  # pacman -Syu
  # yay -Syu
  clean_system large normal fail/gnome-thumbnail-factory
else
  clean_system large normal fail/gnome-thumbnail-factory
fi
