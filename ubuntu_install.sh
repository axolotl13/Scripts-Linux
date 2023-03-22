#!/bin/bash

read -p '¿Desea actualizar?, Escribe y para continuar: ' -r respuesta
if [ "$respuesta" = "y" ]; then
  echo "sudo apt update -y && sudo apt upgrade"
  echo "Estas Actualizado"
  sleep 3
  clear
  read -p '¡Deseas instalar codecs, build-essential ademas de otras herramientas de desarrollo?: ' -r respuesta
  if [ "$respuesta" = "y" ]; then
    sudo apt install git curl ubuntu-restricted-extras acpi-call-dkms tlp tlp-rdw python3-pip python3-dev meson nmap build-essential zsh ssh
    sudo pip3 install beautifulsoup4 requests mycli
    echo "Instalación Completada"
  fi
  echo
  read -p '¡Deseas instalar software recomendado?: ' -r respuesta
  if [ "$respuesta" = "y" ]; then
    sudo apt install gimp inkscape blender wget htop lm-sensors lollypop tilix dconf-editor vlc mpv vim audacity filezilla gthumb
    gnome-tweak-tool chrome-gnome-shell x11-utils
    echo "Instalación Completada"
  fi
else
  echo 'No se realizo ningún acción.'
fi
