#!/bin/bash

# Montar unidad automáticamente
ls -la /dev/disk/by-uuid/
while [ "$filesystem" = "ntfs" ]; do
  let "a += 1"
  mkdir -p "/mnt/Multimedia"$a
  mount $device -t $filesystem "/scanmount/drive"$a
  filesystem="1"
done

# Encriptar
cd "$HOME"
mkdir -p .encrypt
gocryptfs --init .encrypt
mkdir -p Escritorio/Null
gocryptfs .encrypt Escritorio/Null

ifusermount -u Null

# Buscar archivos
files=()
contador=0
if [ "$(find *.sh)" ]; then
  echo "Se encontraron archivos sh"
else
  echo "No se encontro nada"
fi

for i in $(find *.sh); do
  files[$contador]="$i"
  contador+=1
done

for deb in ${files[@]}; do
  echo $deb
done

# Calcula temperatura
temp="$(cat /sys/class/thermal/thermal_zone0/temp)"
core=$((temp / 1000))

if (($core > 56)); then
  notify-send "La temperatura es" "$core"
fi

# fzf
fif() {
  rg \
    --column \
    --line-number \
    --no-column \
    --no-heading \
    --fixed-strings \
    --ignore-case \
    --hidden \
    --follow \
    --glob '!.git/*' "$1" |
    awk -F ":" '/1/ {start = $2<5 ? 0 : $2 - 5; end = $2 + 5; print $1 " " $2 " " start ":" end}' |
    fzf --preview 'bat --wrap character --color always {1} --highlight-line {2} --line-range {3}' --preview-window wrap
}
fif

# tmp

TMP='/tmp/swap'
mkdir $TMP
chwon -R $user:plugdev swap
