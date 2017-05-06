#!/bin/bash

#====================================================
#	System Request:Debian 7+/Ubuntu 14.04+/Centos 6+
#	Author:	wulabing
#	Dscription: SSR glzjin server for manyuser (only)
#	Version: 1.1
#	Blog: https://www.wulabing.com
#	Special thanks: Toyo
#====================================================

sh_ver="1.1"
libsodium_folder="/etc/libsodium"
shadowsocks_install_folder="/root"
shadowsocks_folder="${shadowsocks_install_folder}/shadowsocks"

#fonts color
Green="\033[32m" 
Red="\033[31m" 
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"


#notification information
Info="${Green}[Info]${Font}"
OK="${Green}[OK]${Font}"
Error="${Red}[Error]${Font}"
Notification="${Yellow}[Notification]${Font}"

check_system(){
	if [[ -f /etc/redhat-system ]]; then
		system="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		system="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		system="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		system="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		system="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		system="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		system="centos"
	else 
		system="other"
    fi
}
basic_installation(){
	if [[ ${system} == "centos" ]]; then
		yum -y install vim tar wget git 
	elif [[ ${system} == "debian" || ${system} == "ubuntu" ]]; then
		apt-get update
		apt-get -y install vim tar wget git 
	else
		echo -e "${Error} Don't support this System"
		exit 1
	fi
}

dependency_installation(){
	if [[ ${system} == "centos" ]]; then
		yum -y install python-setuptools && easy_install pip
		yum -y install git
	elif [[ ${system} == "debian" || ${system} == "ubuntu" ]]; then
		apt-get -y install python-setuptools && easy_install pip
		apt-get -y install git
	fi
	
}
development_tools_installation(){
	if [[ ${system} == "centos" ]]; then
		yum -y groupinstall "Development Tools"
		if [[ $? -ne 0 ]]; then
			echo -e "${Error} Development Tools installation FAIL"
			exit 1
		fi
	else
		apt-get -y install build-essential 
		if [[ $? -ne 0 ]]; then
			echo -e "${Error} build-essential installation FAIL"
			exit 1
		fi
	fi
	
}
libsodium_installation(){
	mkdir -p ${libsodium_folder} && cd ${libsodium_folder}
	wget https://github.com/jedisct1/libsodium/releases/download/1.0.10/libsodium-1.0.10.tar.gz
	if [[ ! -f ${libsodium_folder}/libsodium-1.0.10.tar.gz ]]; then
		echo -e "${Error} libsodium download FAIL"
		exit 1
	fi
	tar xf libsodium-1.0.10.tar.gz && cd libsodium-1.0.10
	./configure && make -j2 && make install
	if [[ $? -ne 0 ]]; then 
		echo -e "${Error} libsodium install FAIL"
		exit 1
	fi
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
}
SSR_dependency_installation(){
	if [[ ${system} == "centos" ]]; then
		cd ${shadowsocks_folder}
		yum -y install python-devel
		yum -y install libffi-devel
		yum -y install openssl-devel
		pip install -r requirements.txt		
	else
		pip install cymysql
	fi
}

SSR_installation(){
	check_system
	basic_installation
	dependency_installation
	development_tools_installation
	libsodium_installation
	
	
	cd ${shadowsocks_install_folder} && git clone -b manyuser https://github.com/glzjin/shadowsocks.git 
	cd shadowsocks && cp apiconfig.py userapiconfig.py && cp config.json user-config.json
	
	SSR_dependency_installation
	
	echo -e "${OK} SSR manyuser for glzjin installation complete"
}

SSR_installation
