#!/bin/bash

#====================================================
#	System Request:Debian 7+/Ubuntu 14.04+/Centos 6+
#	Author:	wulabing
#	Dscription: SSR glzjin server for manyuser (only)
#	Version: 4.0
#	Blog: https://www.wulabing.com
#	Special thanks: Toyo
#====================================================

sh_ver="4.0"
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
	wget https://github.com/jedisct1/libsodium/releases/download/1.0.16/libsodium-1.0.16.tar.gz
	if [[ ! -f ${libsodium_folder}/libsodium-1.0.16.tar.gz ]]; then
		echo -e "${Error} ${RedBG} libsodium download FAIL ${Font}"
		exit 1
	fi
	tar xf libsodium-1.0.16.tar.gz && cd libsodium-1.0.16
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
		pip install cymysql==0.8.4
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
modify_ANTISSATTACK(){
	sed -i '/ANTISS/c \ANTISSATTACK = '${ANTISSATTACK}'' ${config}
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
modify_MYSQL_HOST(){
	sed -i '/MYSQL_HOST/c \MYSQL_HOST = '\'${MYSQL_HOST}\''' ${config}
}
modify_MYSQL_PORT(){
	sed -i '/MYSQL_PORT/c \MYSQL_PORT = '${MYSQL_PORT}'' ${config}
}
modify_MYSQL_USER(){
	sed -i '/MYSQL_USER/c \MYSQL_USER = '\'${MYSQL_USER}\''' ${config}
}
modify_MYSQL_PASS(){
	sed -i '/MYSQL_PASS/c \MYSQL_PASS = '\'${MYSQL_PASS}\''' ${config}
}
modify_MYSQL_DB(){
	sed -i '/MYSQL_DB/c \MYSQL_DB = '\'${MYSQL_DB}\''' ${config}
}
modify_MYSQL(){
	modify_MYSQL_HOST
	modify_MYSQL_PASS
	modify_MYSQL_PORT
	modify_MYSQL_USER
	modify_MYSQL_DB
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
	stty erase '^H' && read -p "CLOUDSAFE_ON(0 or 1,default:0,advise:0!):" CLOUDSAFE
	[[ -z ${CLOUDSAFE} ]] && CLOUDSAFE="0"
	stty erase '^H' && read -p "ANTISSATTACK(0 or 1,default:0):" ANTISSATTACK
	[[ -z ${ANTISSATTACK} ]] && ANTISSATTACK="0"
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
	
	cd ${shadowsocks_install_folder} && git clone https://github.com/wulabing/shadowsocks.git 
	cd shadowsocks && cp apiconfig.py userapiconfig.py && cp config.json user-config.json
	
	SSR_dependency_installation


#final option
	modify_ALL
	iptables_OFF

	echo -e "${OK} ${GreenBG} SSR manyuser for glzjin 安装完成 ${Font}"
	sleep 1
}

if_install(){
	[[ -d ${shadowsocks_folder} && -f ${config} ]] && {
		echo -e "${OK} ${GreenBG} ShadowsocksR glzjin 已安装 ${Font}"
	} || {
		echo -e "${Error} ${RedBG} ShadowsocksR glzjin 未安装，请在安装后执行相关操作 ${Font}"
		exit 1
	}
}

option(){
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
modify_module(){
	read -p "请输入 $1 修改内容: " $1
	modify_$1
	[[ $? -eq 0 ]] && {
		echo -e "${OK} ${GreenBG} $1 修改成功 请重新启动后端 ${Font}"
	} || {
		echo -e "${Error} ${RedBG} $1 修改失败 ${Font}"
	}	
}
install_management(){
		check_system
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
modify_management(){
	if_install
	echo -e "${Red}请选择要修改的内容 ${Font}"
	echo -e "${GreenBG}   公共内容   ${Font}"
	echo -e "1. NODE_ID（节点编号）"
	echo -e "2. SPEEDTEST（测速周期）"
	echo -e "3. CLOUDSAFE（云安全，非常不建议开启）"
	echo -e "4. ANTISSATTACK（ss攻击抵抗，自动封禁连接方式或密码错误的IP）"
	echo -e "5. MU_SUFFIX"
	echo -e "6. MU_REGEX"
	echo -e	"${GreenBG}   webapi模式相关内容   ${Font}"
	echo -e "7. WEBAPI_URL"	
	echo -e "8. WEBAPI_TOKEN" 
	echo -e "${GreenBG}   glzjinmod模式相关内容   ${Font}"
	echo -e "9. MYSQL_HOST（数据库主机）"
	echo -e "10.MYSQL_PORT（数据库端口）"
	echo -e "11.MYSQL_USER（数据库用户名）"
	echo -e "12.MYSQL_PASSWORD（数据库密码）"
	echo -e "13.MYSQL_DB（数据库名称）"
	read -p "input:" modify
	case ${modify} in 
		1)
			modify_module "NODE_ID"
			;;
		2)
			modify_module "SPEED_TEST"
			;;
		3)
			modify_module "CLOUDSAFE"
			;;
		4)
			modify_module "ANTISSATTACK"
			;;
		5)
			modify_module "MU_SUFFIX"
			;;
		6)
			modify_module "MU_REGEX"
			;;
		7)
			modify_module "WEBAPI_URL"
			;;
		8)
			modify_module "WEBAPI_TOKEN"
			;;
		9)
			modify_module "MYSQL_HOST"
			;;
		10)
			modify_module "MYSQL_PORT"
			;;
		11)
			modify_module "MYSQL_USER"
			;;
		12)
			modify_module "MYSQL_PASS"
			;;
		13)
			modify_module "MYSQL_DB"
			;;
		*)
			echo -e "${RedBG} 请输入正确的序号 ${Font}"
			exit 1
			;;
	esac
}
uninstall_management(){
	if_install
	rm -rf ${shadowsocks_folder}
	echo -e "${OK$ {GreenBG} shadowsocks glzjin 卸载完成 ${Font}"
	exit 0
}
start_management(){
	command -v supervisord >/dev/null
	if [[ $? -ne 0  ]];then
		echo -e "${Notification} 检测到未安装 supervisord"
		/root/shadowsocks/logrun.sh
		sleep 2
		echo -e "${OK} ${GreenBG} 后端已启动 ${Font}"
	else
		echo -e "${OK} 检测到已安装 supervisord"
		command -v systemctl >/dev/null
		if [[  $? -ne 0 ]];then
			service supervisord start
			sleep 2
			[[ `ps -ef | grep supervisor |grep -v grep | wc -l` -ge 1 ]] && {
				echo -e "${OK} ${GreenBG} 后端（supervisord）已启动 ${Font}"
			} || {
				echo -e "${Error} ${RedBG} 后端启动失败 ${Font}"
				exit 1
			}
		else
			systemctl start supervisor
			sleep 2
			[[ `ps -ef | grep supervisor |grep -v grep | wc -l` -ge 1 ]] && {
				echo -e "${OK} ${GreenBG} 后端（supervisord）已启动 ${Font}"
			} || {
				echo -e "${Error} ${RedBG} 后端启动失败 ${Font}"
				exit 1
			}
		fi
	fi

}
stop_management(){
	command -v supervisord >/dev/null
	if [[ $? -ne 0 ]];then
		echo -e "${Notification} 检测到未安装 supervisord"
		/root/shadowsocks/stop.sh
		sleep 2
		echo -e "${OK} ${GreenBG} 后端已关闭 ${Font}"
	else
		echo -e "${OK} 检测到已安装 supervisord"
		command -v systemctl >/dev/null
		if [[ $? -ne 0 ]];then
			service supervisord stop
			sleep 2
			[[ `ps -ef | grep supervisor |grep -v grep | wc -l` -eq 0 ]] && {
				echo -e "${OK} ${GreenBG} 后端（supervisord）已关闭 ${Font}"
			} || {
				echo -e "${Error} ${RedBG} 后端关闭失败 ${Font}"
				exit 1
			}
		else
			systemctl stop supervisor
			sleep 2
			[[ `ps -ef | grep supervisor |grep -v grep | wc -l` -eq 0 ]] && {
				echo -e "${OK} ${GreenBG} 后端（supervisord）已关闭 ${Font}"
			} || {
				echo -e "${Error} ${RedBG} 后端关闭失败 ${Font}"
				exit 1
			}
		fi
	fi
}
force_stop(){
	supervisor_pid=` ps -ef | grep supervisor |grep -v grep|awk '{print $2}'`
	ss_pid=` ps -ef | grep server.py |grep -v grep|awk '{print $2}' `
	kill -9 ${supervisor_pid} ${ss_pid}
	echo -e "${OK} ${GreenBG} 后端（supervisord）已关闭 ${Font}"
}
management(){
	case $1 in
		install)
			install_management
			;;
		modify)
			modify_management
			;;
		uninstall)
			uninstall_management
			;;
		start)
			start_management
			;;
		stop)
			stop_management
			;;
		restart)
			stop_management
			start_management
			;;
		fstop)
			force_stop
			;;
		status)
			if [[ `ps -ef | grep server.py |grep -v grep | wc -l` -ge 1 ]];then
				echo -e "${OK} ${GreenBG} 后端已启动 ${Font}"
			else
				echo -e "${OK} ${RedBG} 后端未启动 ${Font}"
				exit 1
			fi
			;;
		*)
			echo -e "${Notification} Usage:{start|stop|fstop|status|install|uninstall|modify}"
			exit 1
			;;
	esac
}
management $1

