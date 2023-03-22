#!/bin/bash

format_partition() {
  read -p "¿Desea formatear $name? (y or n): " -r res
  if [[ $res != "y" ]]; then
    echo "No se ha formateado"
  else
    read -p "Que formato (fat, swap, ext4): " -r res
    if [[ -z $res ]]; then
      echo "Por favor llene el campo"
    else
      if [[ $name_volume ]]; then
        if [[ $res != "mkswap" ]]; then
          mkfs."$res" /dev/"$name_volume"/"$name"
          echo "done"
        else
          mkswap /dev/"$name_volume"/"$name"
          echo "done"
        fi
      else
        if [[ $res = "swap" ]]; then
          read -p "Elegir partición /dev/(nvme0n1xx): " -r disk
          mkswap /dev/"$disk"
          echo "done"
        elif [[ $res = "fat" ]]; then
          read -p "Elegir partición /dev/(nvme0n1xx): " -r disk
          mkfs.fat -F 32 /dev/"$disk"
          echo "done"
        else
          read -p "Elegir partición /dev/(nvme0n1xx): " -r disk
          mkfs."$res" /dev/"$disk"
          echo "done"
        fi
      fi
    fi
  fi
}

create_lvm() {
  read -p "¿Crear volumen lógico para $1? (y or n): " -r res
  if [[ $res != "y" ]]; then
    echo "No se creo el volumen para $1"
  else
    read -e -p 'Nombre: ' -i "$1" -r name
    echo "El valor 0 significa que se usara todo el espacio del disco disponible"
    read -p 'Tamaño(GB): ' -r size
    # Filtro para no admitir valores vacíos.
    if [ -z "$name" ] || [ -z "$size" ]; then
      echo "Por favor llenar todos los campos, intente de nuevo"
    else
      # Filtro para aceptar solo números.
      if ! [[ $size =~ ^[0-9]+$ ]]; then
        echo "Ingrese solo números"
      else
        echo "Creando volumen para $1 con el nombre de $name con tamaño de ${size}G"
        if [[ $size -eq 0 ]]; then
          lvcreate -l 100%FREE "$name_volume" -n "$name"
          format_partition "$name_volume" "$name"
        else
          lvcreate -L "${size}G" "$name_volume" -n "$name"
          format_partition "$name_volume" "$name"
        fi
      fi
    fi
  fi
}

create_partition() {
  partitions=(boot efi swap root home)
  list_partition=()
  for partition in "${partitions[@]}"; do
    read -p "¿Agregar partición para $partition?, (y or n): " -r res
    if [[ $res != "y" ]]; then
      echo "No se agrego la partición para $partition"
    else
      list_partition+=("$partition")
      echo "done"
    fi
  done
  if [[ $name_volume ]]; then
    for name in "${list_partition[@]}"; do
      create_lvm "$name" "$name_volume"
    done
  else
    for name in "${list_partition[@]}"; do
      format_partition "$name"
    done
  fi
}

lmv_luks() {
  echo "Crear un contenedor cifrado con LUKS en la partición del «sistema»"
  lsblk
  echo "Selecciona la partición a encriptar:"
  read -p '/dev/(nvme0n1xx): ' -r partition
  if [[ $(cryptsetup luksFormat /dev/"$partition") ]]; then
    read -p 'Abrir y nombrar el nuevo contenedor como: ' -r name_luks
    cryptsetup open /dev/"$partition" "$name_luks"
    echo "Crear un volumen físico sobre el contenedor LUKS abierto $name_luks"
    pvcreate /dev/mapper/"$name_luks"
    read -p 'Crear y nombra un grupo de volúmenes; Nombrar: ' -r name_volume
    vgcreate "$name_volume" /dev/mapper/"$name_luks"
    echo "Crear varios volúmenes lógicos en el grupo de volúmenes $name_volume"
    create_partition "$name_volume"
  else
    echo "Partición no encontrada"
  fi
}

# echo "Montar los sistemas de archivos"
# echo "Montar root sobre mnt"
# mount /dev/avocado/root /mnt
# echo "Crear la carpeta home,boot,efi sobre mnt"
# mkdir -p /mnt/{home,boot/efi}
# echo "Montar home sobre mnt/home"
# mount /dev/avocado/home /mnt/home
# echo "Montar boot sobre mnt/boot"
# mount /dev/sda2 /mnt/boot
# echo "Montar efi sobre mnt/boot/efi"
# mount /dev/sda1 /mnt/boot/efi

inside_chroot() {
  read -e -p "¿Desea definir zona horaria como México?, (y or n): " -i "y" -r res
  if [[ $res != "y" ]]; then
    echo "No se ha definido la zona horaria"
  else
    ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
    echo "done"
  fi
  read -e -p "¿Desea descomentar línea en el archivo locale.gen con el valor es_MX?, (y or n): " -i "y" -r res
  if [[ $res != "y" ]]; then
    echo "No se ha generado el locale.gen"
  else
    sed -i 's/#es_MX.UTF-8/es_MX.UTF-8/g' /etc/locale.gen
    echo "Se ha generado locale.gen"
    locale-gen
    cat </etc/locale.gen | grep es_MX
    echo "done"
  fi
  read -e -p "¿Crear archivo locale.conf con el valor es_MX?, (y or n): " -i "y" -r res
  if [[ $res != "y" ]]; then
    echo "No se configuro el locale.conf"
  else
    echo "LANG=es_MX.UTF-8" >/etc/locale.conf
    cat /etc/locale.conf
    echo "done"
  fi
  read -e -p "¿Establecer teclado de la consola con el valor la-latin1?, (y or n): " -i "y" -r res
  if [[ $res = "y" ]]; then
    echo "KEYMAP=la-latin1" >/etc/vconsole.conf
    cat /etc/vconsole.conf
    echo "done"
  fi
  read -e -p "¿Crear hostname?, (y or n): " -i "y" -r res
  if [[ $res != "y" ]]; then
    echo "No se establecio el hostname"
  else
    read -e -p "Nombre para el hostname (Default): " -i "JOKERBOOK" -r res
    if [ -z "$res" ]; then
      echo "No se permite espacios en blanco"
      echo "Intente de nuevo"
    else
      echo "$res" >/etc/hostname
      cat /etc/hostname
      echo "done"
    fi
  fi
}

chroot() {
  if [[ $(ping -c 3 google.com) ]]; then
    echo "Deseas añadir hooks (keyboard, keymap, encrypt y lvm2) en /etc/mkinitcpio.conf, (necesario instalar lvm2)"
    read -p "(y or n): " -r hooks
    if [[ $hooks = "y" ]]; then
      sed -i 's/modconf/keymap modconf/g' /etc/mkinitcpio.conf
      sed -i 's/filesystems/encrypt lvm2 filesystems/g' /etc/mkinitcpio.conf
      cat </etc/mkinitcpio.conf | grep HOOKS
      echo "done"
    fi
    echo "Generar initramfs"
    mkinitcpio -P
    echo "Instalar GRUB"
    read -e -p "Directorio donde se instalo boot: " -i "/boot" -r dirboot
    read -e -p "Directorio donde se instalo efi: " -i "/efi" -r direfi
    read -e -p "Establecer ID: " -i "Arch" -r bootid
    if [ -z "$dirboot" ] || [ -z "$direfi" ]; then
      echo "No se ha instalado GRUB, intente de nuevo"
    else
      grub-install --target=x86_64-efi --boot-directory="$dirboot" --efi-directory="$direfi" --bootloader-id="$bootid"
      echo "Generar GRUB"
      grub-mkconfig -o /boot/grub/grub.cfg
      echo "done"
    fi
    echo "Establecer Contraseña"
    password
    echo "done"
  else
    echo "Intenta conectarte a una red inalámbrica"
  fi
}

create_user() {
  read -p "¿Desea crear nuevo usuario? (y or n): " -r res
  if [[ $res = "y" ]]; then
    read -e -p "Nombre: " -i "joker" -r name
    useradd -m -G wheel -s /bin/bash "$name"
    echo "Establecer contraseña"
    passwd "$name"
    echo "Descomentar linea en /etc/sudoers"
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers
    cat </etc/sudoers | grep %wheel
    echo "done"
  fi
}

sofware_commons() {
  commons=(dhcpcd ntfs-3g pipewire wireplumber pdftricks webp-pixbuf-loader kitty mpv vlc rclone inkscape lollypop gthumb man-db smartmontools
    android-tools scrcpy obs-studio streamlink youtube-dl yt-dlp unzip unrar sshfs vulkan-radeon)
}

wifi_connect() {
  echo "Generar archivo de conexión"
  # Pide el nombre SSID, si no se le pasa un valor, este toma el valor HIDDEN.
  read -e -p "SSID: " -i "HIDDEN" -r ssid
  read -p "Contraseña: " -r passw
  read -e -p "Guardar como: " -i "HIDDEN" -r file
  # Comprueba si los parametros ssid, passw o file esten vacios.
  if [ -z "$ssid" ] || [ -z "$passw" ] || [ -z "$file" ]; then
    echo "Error, por favor llena todos los campos"
  else
    if [[ ${#passw} -ge 8 ]]; then
      wpa_passphrase "$ssid" "$passw" >/tmp/"$file".conf
      # Comprueba si la contrasenia es mayor o igual que 8.
      echo "Buscar interfaces de red"
      ip link show
      read -p "Elige e inicia la interfaz de red: " -r wifi
      if [ -z "$wifi" ]; then
        echo "Error, trata de llenar el campo"
      else
        if [[ $(ip link set "$wifi" up) ]]; then
          echo "Conectarse atraves del archivo generado anteriormente"
          wpa_supplicant -B -i "$wifi" -c /tmp/"$file".conf
          echo "Iniciar conexión"
          dhcpcd wifi
          echo "done"
        else
          echo "Dispositivo no disponible"
        fi
      fi
    else
      echo "Introduce contraseña con 8 o más caracteres"
    fi
  fi
}

wifi() {
  echo "Importante instalar el paquete wpa_supplicant"
  if [[ $(pacman -Qs wpa_supplicant) ]]; then
    wifi_connect
  else
    echo "Se detecto que el paquete wpa_supplicant no esta instalado"
    echo "Instalando wpa_supplicant"
    pacman -S wpa_supplicant
    read -p "¿Iniciar conexión?, (y or n): " -r up
    if [[ $up = "y" ]]; then
      wifi_connect
    fi
  fi
}

yay_package() {
  lista=(visual-studio-code-bin google-chrome spotify spicetify-cli typora minecraft-launcher ttf-ms-fonts rts5227-dkms)
  chrome-gnome-shell
  for item in "${lista[@]}"; do
    read -p "Instalar ${item}, (y or n): " -r res
    if [[ $res = "y" ]]; then
      yay -S "${item}"
      if [[ $item = "rts5227-dkms" ]]; then
        sudo pacman -Sy linux-lts-headers dkms
        echo "done"
      fi
    fi
  done
}

yay_install() {
  if [[ $(pacman -Qs yay) ]]; then
    yay_package
  else
    read -p "¿Desea instalar yay?, (y or n)" -r res
    if [[ $res = "y" ]]; then
      echo "Clonar repositorio yay"
      git clone https://aur.archlinux.org/yay.git /tmp/yay
      cd /tmp/yay
      echo "Instalando yay"
      makepkg -si
      yay_package
      echo "done"
    else
      echo "No se instalo yay"
    fi
  fi
}

gnome() {
  pkg=(baobab eog evince file-roller gdm gedit gnome-{backgrounds,calculator,calendar,characters,clocks,color-manager,contacts,control-center,
    disk-utility,font-viewer,keyring,logs,menus,remote-desktop,session,settings-daemon,shell,shell-extensions,software,system-monitor,terminal,
    user-docs,user-share,video-effects,tweaks,sound-recorder,boxes,software-packagekit-plugin} grilo-plugins gvfs gvfs-{afc,goa,google,gphoto2,mtp,nfs,smb} malcontent mutter
    nautilus rygel sushi tracker tracker-miners tracker3-miners vino xdg-user-dirs-gtk simple-scan dconf-editor chrome-gnome-shell power-profiles-daemon
    gtk-engine-murrine libsecret)

  pacman -Sy "${pkg[@]}"
  echo "Habilitar gdm al inicio"
  systemctl enable gdm
  read -e -p "¿Instalar NetworkManager y extras?, (y or n): " -i "y" -r netm
  if [[ $netm = "y" ]]; then
    pacman -S networkmanager networkmanager-openvpn networkmanager-pptp networkmanager-vpnc network-manager-sstp networkmanager-l2tp
    echo "Habilitar NetworkManager al inicio"
    systemctl enable NetworkManager
  else
    wifi
  fi
  echo "Habilitar modos de energia"
  systemctl enable power-profiles-daemon
  read -p "¿Deshabilitar actualizaciones automaticas en Gnome Software?, (y or n)?: " -r update
  if [[ $update = "y" ]]; then
    gsettings set org.gnome.software download-updates false
  fi
  read -p "¿Instalar extensiones para nautilus?, (y or n): " -r nauti
  if [[ $nauti = "y" ]]; then
    pacman -Sy python-nautilus nautilus-{bluetooth,image-converter,sendto,share}
  fi
  # echo "habilitar tema negro"
  # gsettings set org.gnome.desktop.interface color-scheme prefer-dark
  echo "done"
}

dualboot() {
  pacman -S os-prober
  echo "Añadir linea en /etc/default/grub"
  sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/g' /etc/default/grub
  cat <"$grub" | grep OS_PROBER
  echo "done"
}

boot() {
  if [[ $(pacman -Qs grub) ]]; then
    grub=/etc/default/grub
    read -p "Desea desbloquear el arranque de la partición cifrada en el archivo $grub (y or n): " -r resgrub
    if [[ $resgrub = "y" ]]; then
      lsblk
      read -e -p "Ingresa el UUID de la particion encryptada (/dev/sdxX): " -i "sda3" -r sda
      read -e -p "Ingresa nombre del volumen físico: " -i "cryptlvm" -r name_luks
      line=$(ls -l /dev/disk/by-uuid/ | grep "$sda" | awk '{print $9}')
      sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${line} /dev/$sda:$name_luks\"|g" $grub
      cat $grub | grep GRUB_CMDLINE
      echo "done"
    fi
  else
    echo "Instalar grub"
    pacman -S grub
    echo "Soporte para EFI"
    pacman -S efibootmgr
    read -p "Habilitar Dual Boot en el grub, (es necesario el paquete os-prober), (y or n): " -r os
    if [[ $os = "y" ]]; then
      dualboot
    fi
  fi
}
encrypt() {
  echo "Solo añadir esta opción si tienes una particion encriptada"
  read -p "¿Habilitar TRIM?, solo disponible para SSD. (y or n): " -r trim
  if [[ $trim = "y" ]]; then
    boot ssd
  else
    boot hdd
  fi
  # read -p "Desea desbloquear el arranque de la partición cifrada en el archivo $grub (y or n): " resgrub
  # if [[ $resgrub = "y" ]]; then
  # fi
}


hardware_acceleration() {
  echo "Habilitar aceleración por hardware"
  echo "Instalar intel drivers"
  pacman -Sy intel-media-driver libva-utils
  echo "LIBVA_DRIVER_NAME=iHD" >>/etc/environment
}

touch_gesture() {
  gem install fusuma fusuma-plugin-sendkey
}

codecs() {
  gst-plugins-{bad,good,ugly}
}

bluetooth() {
  pacman -Sy bluez bluez-utils gnome-bluetooth
  echo "Habilitar bluetooth al inicio"
  systemctl enable bluetooth
  echo "Iniciar despues de suspención"
  sed -i 's/#AutoEnable=true/AutoEnable=true/g' /etc/bluetooth/main.conf
  cat </etc/bluetooth/main.conf | grep AutoEnable
}

font() {
  terminus-font ttf-{ibm-plex,dejavu,liberation,roboto,ubuntu-font-family,anonymous-pro,cascadia-code,hack,fira-mono,fira-code,inconsolata,
  jetbrains-mono,fira-sans} noto-fonts noto-fonts-emoji adobe-source-{code-pro-fonts,sans-fonts,han-sans-otc-fonts}
}

cups() {
  pacman -S cups system-config-printer
  systemctl enable cups
}

pre_install() {
  read -p "¿Desea establecer el teclado en latinoamerica?, (y or n): " -r res
  if [[ $res != "y" ]]; then
    ls /usr/share/kbd/keymaps/**/*.map.gz
  else
    loadkeys la-latin1
    echo "done"
  fi
  read -p "¿Verificar el modo de arranque?, (y or n): " -r res
  if [[ $res = "y" ]]; then
    ls /sys/firmware/efi/efivars
    echo "done"
  fi
  read -p "¿Conectarse a una red inalámbrica?, (y or n): " -r res
  if [[ $res = y ]]; then
    echo "Utiliza iwctl para conectarse al wifi"
    echo "device list"
    echo "station wlan0 connect SSID"
    sleep 5
    iwctl
  fi
  ping -c 3 archlinux.org
  echo "Actualizar reloj del sistema"
  timedatectl status
  # pacstrap /mnt base base-devel linux-lts linux-firmware
}

fish_install() {
  user=$(whoami)
  read -e -p "¿Desea usar el usario actual como: $user?" -i "$user" -r res
  sudo -s chsh -s /bin/fish "$res"
  fish_config prompt choose arrow
  fish_config prompt save
  set -U fish_greeting
  curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
  fisher install PatrickF1/fzf.fish
}

npm_install() {
  sudo pacman -Sy npm
  npm install -g yarn
  mkdir ~/.npm-global
  npm config set prefix '~/.npm-global'
  echo export PATH=~/.npm-global/bin:"$PATH"
}

docker_install() {
  sudo pacman -Sy docker docker-compose pre-commit
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -aG docker "$user"
}

reflector_install() {
  sudo pacman -Sy reflector
  reflector --latest 5 --country Mexico,United\ States --protocol https --sort rate --save /etc/pacman.d/mirrorlist
  systemctl enable reflector.timer
  systemctl start reflector.timer
}

plymouth() {
  yay -S plymouth
  /etc/mkinitcpio.conf
  HOOKS=(base udev plymouth autodetect keyboard keymap modconf block plymouth-encrypt lvm2 filesystems fsck)

  /etc/default/grub
  GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash rd.udev.log_priority=3 vt.global_cursor_default=0"

  /etc/plymouth/plymouthd.conf

  plymouth-set-default-theme -l
  plymouth-set-default-theme -R theme
}

nvim_install() {
  pip install neovim
  npm install -g neovim
  sudo pacman -Sy xsel luarocks tidy hadolint yamllint pyhton-pylint
  npm install -g prettier
  npm install --save-dev stylelint stylelint-config-standard
  pip install git+https://github.com/psf/black
  pip install codespell
  pip install isort
  go install mvdan.cc/sh/v3/cmd/shfmt@latest
}

rust_install() {
  sudo pacman -Sy rust cargo
  # mkdir ~/.rustup
}

start() {
  read -p "¿Desea seguir con la pre-instalación?, (y or n): " -r res
  if [[ $res = "y" ]]; then
    pre_install
  fi

  read -p "¿Desea particionar disco?, (y or n): " -r res
  if [[ $res = "y" ]]; then
    read -p "1: Instalación normal, 2: LVM on LUKS: " -r res
    case "$res" in
    1)
      create_partition
      echo "done"
      ;;
    2)
      lvm_luks
      echo "done"
      ;;
    *)
      echo "No hubio cambio alguno en el disco"
      ;;
    esac
  fi

  read -p "¿Desea configurar pre-instalación?" -r res
  if [[ $res = "y" ]]; then
    inside_chroot
  fi
  read -p "¿Establecer Usuario?, (y or n): " -r res
  if [[ $res = "y" ]]; then
    create_user
    #passwd
  fi
  coreutils=(bat zoxide glow rsync exa duf dust gtop fd git ripgrep fzf fish neovim wget lm_sensors git htop nmap mdcat)
  read -p "¿Instalar coreutils?, (y or n): " -r res
  if [[ $res = "y" ]]; then
    pacman -Sy "${coreutils[@]}"
    echo "done"
  fi
  read -p "¿Instalar gnome y gnome-extra?, (y or n): " -r res
  if [[ $res = "y" ]]; then
    gnome
  fi
  read -p "¿Instalar microcode?, (y or n): " -r res
  if [[ $res = "y" ]]; then
    pacman -S amd-ucode
    if [[ $(pacman -Qs grub) ]]; then
      grub-mkconfig -o /boot/grub/grub.cfg
      echo "done"
    else
      echo "Por favor instale un arrancador de sistema"
    fi
  fi
  read -p "¿Instalar Wayland?, (y or n): " -r res
  if [[ $res = "y" ]]; then
    pacman -Sy wayland wayland-protocols
    echo "QT_QPA_PLATFORM=wayland" >>/etc/environment
  fi
  read -p "¿Instalar QT?, (y or n): " -r res
  if [[ $res = "y" ]]; then
    pacman -Sy qt5-base qt5-wayland qt5-svg qt6-base qt6-wayland adwaita-{qt5,qt6} qgnomeplatform-{qt5,qt6}
    echo "QT_STYLE_OVERRIDE=adwaita" >>/etc/environment
    if [[ $(pacman -Qs wayland) ]]; then
      pacman -S {qt5,qt6}-wayland
    else
      echo "Soporte para wayland no disponible para QT"
    fi
  fi
  read -p "¿Habilitar descargas paralelas?, (y or n): " -r res
  if [[ $res = "y" ]]; then
    sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 3/g' /etc/pacman.conf
  fi
}

install_spicetify() {
  yay -S spicetify-cli
  sudo chmod a+wr /opt/spotify
  spicetify backup apply enable-devtool
  git clone https://github.com/morpheusthewhite/spicetify-themes.git
  mv Dribbblish ~/.config/spicetify/Themes
  cp dribbblish.js ../../Extensions
  spicetify config extensions dribbblish.js
  spicetify config current_theme Dribbblish color_scheme purple
  spicetify config inject_css 1 replace_colors 1 overwrite_assets 1
  spicetify apply
}

pip install mycli

/etc/sudoers
# Defaults insults

/etc/profile
XDG_RUNTIME_DIR=/run/user/$UID

/etc/pam.d/login
Add "auth optional pam_gnome_keyring.so" at the end of the auth section and
session "optional pam_gnome_keyring.so auto_start" at the end of the session section

# random MAC address
/etc/NetworkManager/conf.d/wifi_rand_mac.conf
# [device-mac-randomization]
# "yes" is already the default for scanning
# wifi.scan-rand-mac-address=yes

# [connection-mac-randomization]
# Randomize MAC for every ethernet connection
# ethernet.cloned-mac-address=random
# Generate a random MAC for each WiFi and associate the two permanently.
# wifi.cloned-mac-address=stable

# Desactivar el envio de nombre de host
/etc/NetworkManager/system-connections/your_connection_file
# [ipv4]
# dhcp-send-hostname=false
# [ipv6]
# dhcp-send-hostname=false

start_samba() {
  systemctl enable smb
  systemctl start smb
  systemctl enable avahi-daemon
  systemctl start avahi-daemon
  useradd guest -s /bin/nologin
  chown -R joker:guest carpeta
  chmod -R 775 carpeta
}

create_ssh() {
  # Crea llave RSA
  # ssh-keygen -b 4096 -C "$(whoami)@$(uname -n)t
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_raspberry_$(date +%Y) -C "$(whoami)@$(uname -n)"
  # Copia la llave al servidor especifico
  ssh-copy-id -i ~/.ssh/id_rsa_raspberry.pub -p $PORT $USER@$HOSTNAME
  # /etc/ssh/sshd_config
  sed -i 's/LogLevel INFO/LogLevel VERBOSE/g' /etc/ssh/sshd_config
  sed -i 's#Subsystem sftp /usr/lib/openssh/sftp-server#Subsystem sftp /usr/lib/ssh/sftp-server -f AUTHPRIV -l INFO#g' /etc/ssh/sshd_config
}

set_hibertacion() {
  # Habilitar hibernación
  sed -i 's/lvm2/lvm2 resume/g' /etc/mkinitcpio.conf
  mkinitcpio -p linux
  # Añadiendo en el grub
  sed -i 's/cryptdevice=UUID=$UUID:$NAME resume=/dev/mapper/$SWAPDEVICE'
  # Generar grub con nuevos cambios
  grub-mkconfig -o /boot/grub/grub.cfg
  touch /etc/polkit-1/rules.d/10-enable-hibernation.rules
  echo '/* Allow hibernation */
  polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.hibernate") {
        return polkit.Result.YES;
    }
  });' > /etc/polkit-1/rules.d/10-enable-hibernation.rules
}

security_boot() {
  sudo openssl req -new -x509 -newkey rsa:2048 -keyout MOK.key -outform DER -out MOK.der -nodes -subj "/CN=<Your name>/"
  sudo mokutil --import MOK.der
  sudo dmesg | grep -i "EFI v"
}

sudo pacman -S efibootmgr

# Crea la nueva entrada de arranque en la tabla de particiones EFI
sudo efibootmgr --create --disk /dev/sda --part 1 --loader /vmlinuz-linux --label "Arch Linux" --unicode 'root=/dev/mapper/vg0-root rw initrd=\initramfs-linux.img initrd=\initramfs-linux-fallback.img'
sudo efibootmgr --disk /dev/sda --part X --create --label "Arch Linux" --loader /path/to/vmlinuz --unicode 'root=UUID=<UUID de la partición raíz> rw initrd=/path/to/initramfs.img'
