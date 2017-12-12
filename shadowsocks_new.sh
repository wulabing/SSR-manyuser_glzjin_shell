#!/bin/bash

#====================================================
#	System Request:Debian 7+/Ubuntu 14.04+/Centos 6+
#	Author:	wulabing
#	Dscription: SSR glzjin server for manyuser (only)
#	Version: 3.0
#	Blog: https://www.wulabing.com
#	Special thanks: Toyo
#====================================================

sh_ver="3.0"
libsodium_folder="/etc/libsodium"
shadowsocks_install_folder="/root"
supervisor_dir="/etc/supervisor"
suerpvisor_conf_dir="${supervisor_dir}/conf.d"
shadowsocks_folder="${shadowsocks_install_folder}/shadowsocks"
config="${shadowsocks_folder}/userapiconfig.py"
debian_sourcelist="/etc/apt/source.list"

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

source /etc/os-release &>/dev/null

check_system(){
    if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Centos ${VERSION_ID} ${Font} "
        INS="yum"
    elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 8 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Debian ${VERSION_ID} ${Font} "
        INS="apt-get"
    elif [[ "${ID}" == "ubuntu" && `echo "${VERSION_ID}" | cut -d '.' -f1` -ge 16 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Ubuntu ${VERSION_ID} ${Font} "
        INS="apt-get"
	elif [[ `rpm -q centos-release |cut -d - -f1` == "centos" && `rpm -q centos-release |cut -d - -f3` == 6 ]];then
		echo -e "${OK} ${GreenBG} 当前系统为 Centos 6 ${Font} "
        INS="yum"
		ID="centos"
		VERSION_ID="6"
    else
        echo -e "${Error} ${RedBG} 当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内，安装中断 ${Font} "
        exit 1
    fi
}
basic_installation(){
	if [[ ${ID} == "centos" ]]; then
		${INS} install tar wget epel-release -y
	else
		sed -i '/^deb cdrom/'d /etc/apt/sources.list
		${INS} update
		${INS} install tar wget -y
	fi
}

dependency_installation(){
		${INS} -y install python-setuptools  && easy_install pip
		if [[ $? -ne 0 ]]; then
			if [[ ${ID} == "centos" ]];then
				echo -e "${OK} ${GreenBG} 尝试 yum 安装 python-pip ${Font}"
				sleep 2
				yum -y install python-pip 
			else
				echo -e "${OK} ${GreenBG} 尝试 apt 安装 python-pip ${Font}"
				sleep 2
				apt-get install python-pip -y
			fi
			if [[ $? -eq 0 ]]; then
				echo -e "${OK} ${GreenBG} pip installation Successfully ${Font}"
				sleep 1
				else
				echo -e "${Error} ${RedBG} pip installation FAIL ${Font}"
				exit 1
			fi
		fi
}
development_tools_installation(){
	if [[ ${ID} == "centos" ]]; then
		${INS} groupinstall "Development Tools" -y
		if [[ $? -ne 0 ]]; then
			echo -e "${Error} ${RedBG} Development Tools installation FAIL ${Font}"
			exit 1
		fi
	else
		${INS} install build-essential -y
		if [[ $? -ne 0 ]]; then
			echo -e "${Error} ${RedBG} build-essential installation FAIL ${Font}"
			exit 1
		fi
	fi
	
}
libsodium_installation(){
	mkdir -p ${libsodium_folder} && cd ${libsodium_folder}
	wget https://github.com/jedisct1/libsodium/releases/download/1.0.13/libsodium-1.0.13.tar.gz
	if [[ ! -f ${libsodium_folder}/libsodium-1.0.13.tar.gz ]]; then
		echo -e "${Error} ${RedBG} libsodium download FAIL ${Font}"
		exit 1
	fi
	tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
	./configure && make -j2 && make install
	if [[ $? -ne 0 ]]; then 
		echo -e "${Error} ${RedBG} libsodium install FAIL ${Font}"
		exit 1
	fi
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig

	rm -rf ${libsodium_folder}

}
SSR_dependency_installation(){
	if [[ ${ID} == "centos" ]]; then
		cd ${shadowsocks_folder}
		${INS} install python-devel libffi-devel openssl-devel -y
		pip install -r requirements.txt
		pip install requests		
	else
		pip install cymysql
		pip install requests
	fi
}
supervisor_installation(){
	if [[ ! -d ${shadowsocks_folder} ]]; then
		read -p "请输入shadowsocks所在目录绝对路径（eg：/root/shadowsocks）" shadowsocks_folder
	fi
	if [[ ${ID} == "centos" ]];then
		yum -y install supervisor
	else
		apt-get install supervisor -y
	fi
	if [[ $? -ne 0 ]]; then 
		echo -e "${Error} ${RedBG} supervisor 安装失败 ${Font}"
		exit 1
	else
		echo -e "${OK} ${GreenBG} supervisor 安装成功 ${Font}"
		sleep 1
	fi
	

}
supervisor_conf_modify_debian(){
	cat>${suerpvisor_conf_dir}/shadowsocks.conf<<EOF
[program:shadowsocks]
command = python ${shadowsocks_folder}/server.py
stdout_logfile = /var/log/ssmu.log
stderr_logfile = /var/log/ssmu.log
user = root
autostart = true
autorestart = true
EOF

	echo -e "${OK} ${GreenBG} supervisor 配置导入成功 ${Font}"
	sleep 1
}
supervisor_conf_modify_ubuntu(){
	cat>${suerpvisor_conf_dir}/shadowsocks.conf<<EOF
[program:shadowsocks]
command = python ${shadowsocks_folder}/server.py
stdout_logfile = /var/log/ssmu.log
stderr_logfile = /var/log/ssmu.log
user = root
autostart = true
autorestart = true
EOF

	echo -e "${OK} ${GreenBG} supervisor 配置导入成功 ${Font}"
	sleep 1
}
supervisor_conf_modify_centos(){
	cat>>/etc/supervisord.conf<<EOF
[program:shadowsocks]
command = python ${shadowsocks_folder}/server.py
stdout_logfile = /var/log/ssmu.log
stderr_logfile = /var/log/ssmu.log
user = root
autostart = true
autorestart = true
EOF

	echo -e "${OK} ${GreenBG} supervisor 配置导入成功 ${Font}"
	sleep 1
}
modify_API(){
	sed -i '/API_INTERFACE/c \API_INTERFACE = '\'${API}\''' ${config}
}
modify_NODE_ID(){
	sed -i '/NODE_ID/c \NODE_ID = '${NODE_ID}'' ${config}
}
modify_SPEEDTEST(){
	sed -i '/SPEED/c \SPEEDTEST = '${SPEEDTEST}'' ${config}
}
modify_CLOUDSAFE(){
	sed -i '/CLOUD/c \CLOUDSAFE = '${CLOUDSAFE}'' ${config}
}
modify_MU_SUFFIX(){
	sed -i '/MU_SUFFIX/c \MU_SUFFIX = '\'${MU_SUFFIX}\''' ${config}
}
modify_MU_REGEX(){
	sed -i '/MU_REGEX/c \MU_REGEX = '\'${MU_REGEX}\''' ${config}
}
modify_WEBAPI_URL(){
	sed -i '/WEBAPI_URL/c \WEBAPI_URL = '\'${WEBAPI_URL}\''' ${config}
}
modify_WEBAPI_TOKEN(){
	sed -i '/WEBAPI_TOKEN/c \WEBAPI_TOKEN = '\'${WEBAPI_TOKEN}\''' ${config}
}
modify_MYSQL(){
	sed -i '/MYSQL_HOST/c \MYSQL_HOST = '\'${MYSQL_HOST}\''' ${config}
	sed -i '/MYSQL_PORT/c \MYSQL_PORT = '${MYSQL_PORT}'' ${config}
	sed -i '/MYSQL_USER/c \MYSQL_USER = '\'${MYSQL_USER}\''' ${config}
	sed -i '/MYSQL_PASS/c \MYSQL_PASS = '\'${MYSQL_PASS}\''' ${config}
	sed -i '/MYSQL_DB/c \MYSQL_DB = '\'${MYSQL_DB}\''' ${config}
}
selectApi(){
	echo -e "${Yellow} 请选择 API 模式: ${Font}"
	echo -e "1.modwebapi"
	echo -e "2.glzjinmod(mysql_connect)"
	stty erase '^H' && read -p "(default:modwebapi):" API
	if [[ -z ${API} || ${API} == "1" ]]; then
		API="modwebapi"
	elif [[ ${API} == "2" ]]; then
		API="glzjinmod"
	else
		echo -e "${Error} you can only select in 1 or 2"
		exit 1
	fi
}
common_set(){
	stty erase '^H' && read -p "NODE_ID(num_only):" NODE_ID
	stty erase '^H' && read -p "SPEEDTEST_CIRCLE(num_only,default:0):" SPEEDTEST
	[[ -z ${SPEEDTEST} ]] && SPEEDTEST="0"
	stty erase '^H' && read -p "CLOUDSAFE_ON(0 or 1,default:0):" CLOUDSAFE
	[[ -z ${CLOUDSAFE} ]] && CLOUDSAFE="0"
	stty erase '^H' && read -p "MU_SUFFIX(default:zhaoj.in):" MU_SUFFIX
	[[ -z ${MU_SUFFIX} ]] && MU_SUFFIX="zhaoj.in"
	stty erase '^H' && read -p "MU_REGEX(default:%5m%id.%suffix):" MU_REGEX
	[[ -z ${MU_REGEX} ]] && MU_REGEX="%5m%id.%suffix"	
}
modwebapi_set(){
	stty erase '^H' && read -p "WEBAPI_URL(example: https://www.zhaoj.in):" WEBAPI_URL
	stty erase '^H' && read -p "WEBAPI_TOKEN(example: zhaoj.in):" WEBAPI_TOKEN
}
mysql_set(){
	stty erase '^H' && read -p "MYSQL_HOST(IP addr or domain):" MYSQL_HOST
	stty erase '^H' && read -p "MYSQL_PORT(default:3306):" MYSQL_PORT
	[[ -z ${MYSQL_PORT} ]] && MYSQL_PORT="3306"
	stty erase '^H' && read -p "MYSQL_USER(default:root):" MYSQL_USER
	[[ -z ${MYSQL_USER} ]] && MYSQL_USER="root"
	stty erase '^H' && read -p "MYSQL_PASS:" MYSQL_PASS
	stty erase '^H' && read -p "MYSQL_DB(default:sspanel):" MYSQL_DB
	[[ -z ${MYSQL_DB} ]] && MYSQL_DB="sspanel"
}
modify_ALL(){
	modify_CLOUDSAFE
	modify_API
	modify_MU_REGEX
	modify_MU_SUFFIX
	modify_MYSQL
	modify_NODE_ID
	modify_SPEEDTEST
	modify_WEBAPI_TOKEN
	modify_WEBAPI_URL
}
iptables_OFF(){
	systemctl disable firewalld &>/dev/null
	systemctl disable iptables &>/dev/null
	chkconfig iptables off &>/dev/null
	iptables -F	&>/dev/null
}
SSR_installation(){
#select api

	selectApi
	echo ${API}
	common_set

	if [[ ${API} == "modwebapi" ]]; then
		modwebapi_set
	else
		mysql_set
	fi
	
#basic install	
	basic_installation
	dependency_installation
	development_tools_installation
	libsodium_installation
	
	cd ${shadowsocks_install_folder} && git clone -b manyuser https://github.com/glzjin/shadowsocks.git 
	cd shadowsocks && cp apiconfig.py userapiconfig.py && cp config.json user-config.json
	
	SSR_dependency_installation


#final option
	modify_ALL
	iptables_OFF

	echo -e "${OK} ${GreenBG} SSR manyuser for glzjin 安装完成 ${Font}"
	sleep 1
}

option(){
	check_system
	sleep 2
	echo -e "${Red} 请选择安装内容 ${Font}"
	echo -e "1. SSR + supervisor"
	echo -e "2. SSR "
	echo -e "3. supervisor"
	read -p "input:" number
	case ${number} in
		1)
			SSR_installation
			supervisor_installation
			supervisor_conf_modify_${ID}
			;;
		2)
			SSR_installation
			;;
		3)
			supervisor_installation
			supervisor_conf_modify_${ID}
			;;
		*)
			echo -e "${Error} ${RedBG} 请输入正确的序号 ${Font}"
			exit 1
			;;
	esac
}

option
