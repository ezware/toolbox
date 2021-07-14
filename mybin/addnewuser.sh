#!/bin/bash
user=$1
if [ -z "$2" ]; then
	uid=
else
	uid="-u $2"
fi

if [ -d /home/$user ]; then
	home_flag=-M
else
	home_flag=-m
fi

sudo useradd $home_flag $uid -g support -s /bin/bash $user
(echo "$user":"$user") | sudo chpasswd
sudo chmod g+rx /home/$user
(echo $user;echo $user) | sudo smbpasswd -a $user -s
sudo usermod -G support,docker $user

