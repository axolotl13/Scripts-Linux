#!/bin/bash

start_stream() {
  streamlink="streamlink twitch.tv/"
  if [[ $1 != "" ]]; then
    streamer=$streamlink$1
    mpv="-p mpv"
    if [[ $2 != "" ]]; then
      case $2 in
      audio)
        $streamer audio_only "-p vlc"
        ;;
      *)
        $streamer "$2" "$mpv"
        ;;
      esac
    fi
    if $streamer 720p "$mpv"; then
      echo
    else
      $streamer 720p60 "$mpv"
    fi
  else
    echo "Necesitas almenos una opcion"
    echo "Prueba con './${0} JuanP'"
  fi
}

echo "twitch.tv/$Canal $Formato $Reproductor"
echo "Example: JLP 480 vlc"
sleep 1
start_stream "$@"
