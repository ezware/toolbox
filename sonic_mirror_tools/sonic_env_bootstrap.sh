#!/bin/bash

echo "Bootstraping sonic env..."

curuser=$(whoami)
echo "Current user: $curuser"
#needReplace=$(grep -c "archive.ubuntu" < /etc/apt/sources.list)
#if ((needReplace > 0))
#then
	echo "Modifing repo"
	sudo sed -i 's/cn.archive.ubuntu.com/10.153.3.130/g' /etc/apt/sources.list
	sudo sed -i 's/us.archive.ubuntu.com/10.153.3.130/g' /etc/apt/sources.list
	sudo sed -i 's/security.ubuntu.com/10.153.3.130/g' /etc/apt/sources.list
#fi

sudo apt update

echo "Installing pip, jinja2, j2cli, samba"
sudo apt install -y python-pip python-jinja2 samba
sudo pip install -i http://10.153.3.130/pypi/web/simple --trusted-host 10.153.3.130 j2cli

docker=$(which docker)
if [ -z "$docker" ]; then
	echo "Installing docker"
	sudo apt install -y docker.io
	hasDockerGroup=$(cat /etc/group | grep "docker:")
	if [ -z "$hasDockerGroup" ]; then
		sudo groupadd docker
	fi

	inDockerGroup=$(cat /etc/group | grep "docker:" | grep -c $curuser)
	if ((inDockerGroup < 1))
	then
		noMember=$(cat /etc/group | grep -c 'docker:.*:$')
		if ((noMember))
		then
			adduser=$curuser
		else
			adduser=",$curuser"
		fi
		sudo sed -i "s/docker:\(.*\)$/docker:\1$adduser/" /etc/group
	fi
fi

nginx=$(which nginx)
if [ -z "$nginx" ]; then
	echo "Installing nginx"
	sudo apt install -y nginx
fi

echo "Decompressing www"
tar -xf www.tar.gz
echo "Decompressing sonic-buildimage"
tar -xf sonic-buildimage.201911.tar.gz
echo "Loading sonic-slave-stretch"
sudo docker load -i sonic-slave-stretch.tar.gz
echo "Loading sonic-slave-jessie"
sudo docker load -i sonic-slave-jessie.tar.xz

#nginx init
echo "Starting nginx"
sed -i "/^[ ]*root /root $(pwd)\/www/" /etc/nginx/sites-available/default
sudo systemctl restart nginx

echo "Modifing /etc/hosts"

sudo echo '
172.17.0.1 mirror.opencompute.org
172.17.0.1 storage.googleapis.com
172.17.0.1 chromium.googlesource.com
#10.153.3.130 mirrors.cloud.tencent.com
10.153.3.130 mirrors.h3c.com
172.17.0.1 sonicstorage.blob.core.windows.net
10.153.3.130 mirrors.tuna.tsinghua.edu.cn
10.153.3.130 debian-archive.trafficmanager.net
' >>/etc/hosts

