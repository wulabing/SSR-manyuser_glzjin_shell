# sspanel v3 glzjin 后端一键安装脚本

* 适用于glzjin面板ssr后端的一键安装脚本 实现输入配置信息、以及全自动安装，支持 modwebapi 及 glzjinmod（mysql connect）
* 旧版支持 Ubuntu14.04+ / Centos 6+ / Debian7+ 
* 新版(supervisor版本)支持 Ubuntu16.04+ / Centos 6+ / Debian 8+
* 默认安装目录：/root/shadowsocks

# 安装方法 （ 2017/12/10 更新）
```
git clone https://github.com/wulabing/SSR-manyuser_glzjin_shell.git SSR

cd SSR
```
旧版本安装：

`bash shadowsocks.sh | tee sslog.txt`

新版本安装：

`bash shadowsocks_new.sh | tee sslog.txt`

# 相关目录

后端默认安装目录：`/root/shadowsocks`

supervisor 默认配置目录 ：`/etc/supervisor/conf.d/shadowsocks.conf （Centos:/etc/supervisord.conf）`

# 启动方式

### 未安装 supervisor：

* 启动：`/root/shadowsocks/log.sh`
* 启动（日志模式）：`/root/shadowsocks/logrun.sh`
* 停止：`/root/shadowsocks/stop.sh`
* 日志：`/root/shadowsocks/tail.sh`

### 已安装 supervisor：

* 启动 shadowsocks ：`systemctl start supervisor（centos6：service supervisord start）`
* 停止 shadowsocks ：`systemctl start supervisor（centos6：service supervisord stop）`
* 重启 shadowsocks ：`systemctl restart supervisor（centos6：service supervisord start）`
* 添加 supervisor 开机启动： `systemctl enable supervisor(centos6:chkconfig --add supervisord)`
* 日志 ：`tail -f /var/log/sslog.txt`

# 问题反馈

携带 sslog.txt 文件提交 issue

# 更新
## 2017-12-10
V3.0
### 从本版本开始 仅支持具有 Systemd 特性的发行版系统 并启用 shadowsocks_new.sh 更新，旧版本停止维护

* 1.添加 supervisor 守护程序安装
* 2.添加 选择列表，可以手动选择安装 SSR 或 supervisor 
* 3.修复 webapi模式下运行出现 no module named requests 的情况 （由于缺少 requests 模块）
* 4.改善 部分交互内容

## 2017-08-09
V2.1.2

* 1.调整顺序。优先进行信息输入，然后进入安装流程

## 2017-07-29
V2.1.1

* 1.libsodium 版本由早期 1.0.10 调整至 1.0.13


## 2017-05-07
V2.1

* 1.修复因逻辑问题导致配置文件内容异常从而导致的运行报错
* 2.修复由于 debian 源中有 deb cdrom 而导致的安装中断
* 3.添加了禁用防火墙的相关内容

V2.0

* 1.实现输入配置信息、以及全自动安装，支持 modwebapi 及 glzjinmod（mysql connect）
* 2.修复bug

## 2017-05-06
V1.1

* 1、自动进行相关依赖的安装，支持 ubuntu14.04+ / centos6+ /debian7+ 

