#!/bin/bash

INTEL="/sys/class/backlight/intel_backlight/brightness"
AMD="/sys/class/backlight/amdgpu_bl0/brightness"

# Obtiene el brillo actual del sistema
CONFIG=$(cat $INTEL)
# Obtiene la hora actual en formato de 24hrs
TIME=$(date +"%k")
# Rango valido de brillo para $INTEL
SET=(650 514 408 330 253 167 143 76 33 25)

brightness() {
  if (("$CONFIG" >= $1)); then
    while [ "$CONFIG" -ge "$1" ]; do
      echo "$CONFIG" >"$INTEL"
      CONFIG=$(("$CONFIG" - 1))
      sleep .01
    done
  else
    while [ "$CONFIG" -le "$1" ]; do
      echo "$CONFIG" >"$INTEL"
      CONFIG=$(("$CONFIG" + 1))
      sleep .01
    done
  fi
}

# Si la hora actual es igual a 7am, ejecutar la función para establecer brillo
if (("$TIME" == 7)); then
  brightness "${SET[0]}"
elif (("$TIME" >= 8 && "$TIME" < 12)); then
  brightness "${SET[2]}"
elif (("$TIME" == 12)); then
  brightness "${SET[3]}"
elif (("$TIME" == 13)); then
  brightness "${SET[4]}"
elif (("$TIME" >= 14 && "$TIME" < 16)); then
  brightness "${SET[5]}"
elif (("$TIME" == 16)); then
  brightness "${SET[6]}"
elif (("$TIME" == 17)); then
  brightness "${SET[7]}"
elif (("$TIME" == 18)); then
  brightness "${SET[8]}"
elif (("$TIME" == 19)); then
  brightness "${SET[8]}"
else
  brightness "${SET[8]}"
fi
