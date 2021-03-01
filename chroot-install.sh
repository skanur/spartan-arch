#!/bin/bash

set -e 

# This will be ran from the chrooted env.

user=$1
password=$2
fast=$3

# setup mirrors
if [ "$fast" -eq "1"]
then
    echo 'Setting up mirrors'
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup
    rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
else
    echo 'Skipping mirror ranking because fast'
fi

# setup timezone
echo 'Setting up timezone'
timedatectl set-ntp true
ln -s /usr/share/zoneinfo/America/New_York /etc/localtime
ln -sf /usr/share/zoneinfo/Europe/Helsinki /etc/localtime
hwclock --systohc

# setup keymaps and font
#echo 'Setting up german keymap'
#echo KEYMAP=de-latin1 > /etc/vconsole.conf
#echo FONT=lat9w-16 >> /etc/vconsole.conf

# setup locale
echo 'Setting up locale'
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# setup hostname
echo 'Setting up hostname'
echo 'arch-virtualbox' > /etc/hostname

# disable pacman download timeout because of weird cooperate firewall settings
sed -i '/\[options\]/a DisableDownloadTimeout' /etc/pacman.conf

# build
# echo 'Building'
# mkinitcpio -p linux

# install bootloader
echo 'Installing bootloader'
pacman -S syslinux --noconfirm
sed -i 's/APPEND root=\/dev\/sda3 rw/APPEND root=\/dev\/sda1 rw/g' /boot/syslinux/syslinux.cfg
syslinux-install_update -iam

# install Xorg
echo 'Installing Xorg'
pacman -S --noconfirm xorg xorg-xinit xterm

# install virtualbox guest modules
echo 'Installing VB-guest-modules'
pacman -S --noconfirm virtualbox-guest-modules-arch virtualbox-guest-utils

# vbox modules
echo 'vboxsf' > /etc/modules-load.d/vboxsf.conf

# install dev envt.
echo 'Installing dev environment'
pacman -S --noconfirm git emacs zsh nodejs npm vim wget perl make gcc grep tmux i3 dmenu
pacman -S --noconfirm chromium curl openssh sudo mlocate
pacman -S --noconfirm ttf-hack lxterminal nitrogen ntp dhclient keychain
pacman -S --noconfirm python python-pip pkg-config
pip install pipenv bpython ipython

# install req for pacaur & cower
echo 'Installing dependencies'
pacman -S --noconfirm expac fakeroot yajl openssl

# user mgmt
echo 'Setting up user'
read -t 1 -n 1000000 discard      # discard previous input
echo 'root:'$password | chpasswd
useradd -m -G wheel -s /bin/zsh $user
touch /home/$user/.zshrc
chown $user:$user /home/$user/.zshrc
mkdir /home/$user/org
chown $user:$user /home/$user/org
mkdir /home/$user/workspace
chown $user:$user /home/$user/workspace
echo $user:$password | chpasswd
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

# enable services
systemctl enable ntpdate.service

# preparing post install
wget https://raw.githubusercontent.com/skanur/spartan-arch/master/post-install.sh -O /home/$user/post-install.sh
chown $user:$user /home/$user/post-install.sh

echo 'Done'
startx
