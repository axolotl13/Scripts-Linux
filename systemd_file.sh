#!/bin/bash

create_file() {
    file=/etc/systemd/system
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
    systemctl daemon-reload
    # if [ "$(systemctl --user is-enabled tunnel)" == "disabled" ]; then
    systemctl enable tunnel
    # systemctl start tunnel
    # fi
}

check_ssh() {
    if [ "$(systemctl is-active sshd)" == "active" ] || [ "$(systemctl is-active ssh)" ]; then
        echo "SSH service is running."
        create_file
    else
        echo "SSH service is not running."
        systemctl enable ssh
        systemctl enable sshd
        systemctl start ssh
        systemctl start sshd
        create_file
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

    if [[ ! $(ping -c 3 google.com) ]]; then
        if [ -z "$(which sshd)" ] || [ -z "$(which wget)" ]; then
            case $OS in
            "Ubuntu" | "Debian GNU/Linux")
                apt update && apt upgrade && apt install openssh-server wget -y
                ;;
            "Fedora")
                dnf upgrade && dnf install openssh-server wget -y
                ;;
            "Arch Linux")
                pacman -Syu && pacman -Sy openssh wget
                ;;
            *)
                echo "No se reconoce la distribución $OS"
                exit 1
                ;;
            esac
        fi
        check_ssh
    fi
}

check_os
