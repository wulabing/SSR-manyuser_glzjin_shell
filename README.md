# ShadowsocksR_onekey_shell

适用于glzjin面板ssr后端的一键安装脚本
支持全自动化安装
默认安装目录：/root/shadowsocks
# 安装方法 （2017-07-29更新）

git clone https://github.com/wulabing/SSR-manyuser_glzjin_shell.git SSR

cd SSR

bash shadowsocks.sh

设置完后进入安装目录 默认/root/shadowsocks 执行

git fetch

git checkout aead

git pull

安装完成

# 更新
## version 2.1.1
2017-07-29

1. libsodium 版本由早期 1.0.10 调整至 1.0.13


## version 2.1

2017-05-07

1.修复因逻辑问题导致配置文件内容异常从而导致的运行报错

2.修复由于 debian 源中有 deb cdrom 而导致的安装中断

### 3.添加了禁用防火墙的相关内容

## version 2.0

2017-05-07

1.实现输入配置信息、以及全自动安装，支持 modwebapi 及 glzjinmod（mysql connect）

2.修复bug

## version 1.1

2017-05-06

1、自动进行相关依赖的安装，支持 ubuntu14.04+ / centos6+ /debian7+ 

