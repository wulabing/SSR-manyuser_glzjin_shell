#!/bin/bash

#====================================================
#	System Request:Debian 7+/Ubuntu 14.04+/Centos 6+
#	Author:	wulabing
#	Dscription: SSR server + lotserver
#	Version: 1.0
# 	Blog: https://www.wulabing.com
#   Special thanks: Toyo
#====================================================

config_folder="/etc/shadowsocksr"
config_file="/etc/shadowsocksr/user-config.json"

#字体特殊颜色
Green="\033[32m" 
Red="\033[31m" 
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"


#警示信息
Info="${Green}[Info]${Font}"
Error="${Red}[Error]${Font}"
Tip="${Green}[Notification]${Font}"
check_system(){
	if [ -f /etc/redhat-system ]; then
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
    fi
	bit=`uname -m`
}
dependency_installation(){
	if [ ${system} -eq "centos" ]; then
		yum install vim wget git -y
	elif [ ${system} -eq "debian" || ${system} -eq "ubuntu" ]; then
		apt-get install vim wget git -y
	else
		echo "${Error} Don't support this System"
		exit 1
}

SSR_installation(){
	if [ -f ${config_file} || -f ${config_folder} ]; then
		echo -e "shadowsocksr has been installed"
		exit 1
	fi
	
	dependency_installation 
	
	cd "/etc"
	git clone https://github.com/shadowsocksr/shadowsocksr.git
	if [ !  -d ${config_folder} ]; then
		echo -e "${Error} ShadowsocksR download FAIL"
		exit 1
	fi
	
	

		
}
