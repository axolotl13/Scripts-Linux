#!/bin/bash

# Pequeño script para hacer copias de respaldo en mis carpetas locales
backup_files() {
  GET_DATE=$(date +%Y-%m-%d)
  local backup_path=$HOME/Backups/Thinkbook
  # local backup_pathmc=$HOME/Backups/Minecraft
  cd "$1" || return
  shift 1 # Eliminar argumento 1 en la lista de parametros

  for file in "$@"; do
    echo "Respaldando archivo $file ..."
    zip -r "$backup_path"/"${file}_$GET_DATE.zip" "$file"
    # tar -czvf "$backup_path"/"${file}_$date.tar.gz" "$file"
    sleep 2
  done
}

# Configuraciónes
# backup_files $HOME .myclirc .bashrc .bash_history .mycli-history .minecraft-server .ssh
# backup_files $HOME/.config fontconfig fusuma fish kitty nvim mpv ppsspp systemd spicetify
# backup_files $HOME/.local/share fonts nautilus-python zoxide
backup_files "$HOME/.local/share/fish" "fish_history"
# backup_files $HOME/.local/share/citra-emu sdmc

# Minecraft
# backup_files $HOME/.minecraft/ screenshots api mods resourcepacks skins
# backup_files $HOME/.minecraft/saves PICOCRAFT #ANDRODIA CREATIVO

# Root
# backup_files /etc fstab environment hosts pacman.conf wireguard iptables
# backup_files /etc/samba smb.conf
# backup_files /etc/systemd system
