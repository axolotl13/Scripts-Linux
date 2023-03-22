#!/bin/bash

# Restaura la configuración de iptables
iptables_restore() {
  local path=/etc/iptables/iptables.rules.bck

  if [[ "$(ls $path)" ]]; then
    echo "Restaurando reglas de iptables"
    iptables-restore <$path
  else
    echo "Archivo no Encontrado"
  fi
}

iptables_restore
