#!/bin/bash

function assert_file_exist()
{
    if [ ! -f $1 ]; then
        echo "$1 doesn't exist"
        exit 1
    fi
}

function assert_folder_exist()
{
    if [ ! -d $1 ]; then
        echo "$1 doesn't exist"
        exit 1
    fi
}

# input
# $1 src
# $2 dst
# $3 need_sudo
function backup_file()
{
    assert_file_exist $1
    if [[ $3 -eq 1 ]]; then
      sudo cp -f $1 $2
    else
      cp -f $1 $2
    fi
}

# input
# $1 src
# $2 dst
# $3 need_sudo
function rename_folder()
{
    assert_folder_exist $1
    if [[ $3 -eq 1 ]]; then
      sudo mv $1 $2
    else
      mv $1 $2
    fi
}

# source
dst="/etc/apt/sources.list.`date +%Y%m%d-%H%M%S`"
backup_file "/etc/apt/sources.list" ${dst} 1
sudo bash -c 'cat << EOF > /etc/apt/sources.list
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.ustc.edu.cn/ubuntu/ bionic main restricted universe multiverse
# deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
# deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
# deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse

deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
# deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-security main restricted universe multiverse

# deb http://security.ubuntu.com/ubuntu/ bionic-security main restricted universe multiverse
# # deb-src http://security.ubuntu.com/ubuntu/ bionic-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
# # deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
EOF'

# update system
sudo apt-get -y update
sudo apt-get -y upgrade


# base tool
sudo apt -y install gcc perl make

sudo apt -y install build-essential make cmake bison flex \
        android-tools-fsutils mtd-utils zlib1g-dev lzop \
        python2.7 curl wget git vim samba ssh net-tools


# python libs
python --version
curl -o get-pip.py https://bootstrap.pypa.io/pip/2.7/get-pip.py

sudo python2.7 get-pip.py
pip --version

pip install networkx==1.8.1
pip install xlrd==0.9.3
pip install simplejson==3.17.6
pip install numpy==1.16.5

# git config
SSH_DIR=~/.ssh
dst="${SSH_DIR}.`date +%Y%m%d-%H%M%S`"
if [ -d ${SSH_DIR} ]; then
  rename_folder "${SSH_DIR}" "${dst}" 0
fi
mkdir -p ~/.ssh
ssh-keygen -f ~/.ssh/id_rsa -P ""
git config --global user.name $USER
git config --global user.email ${USER}@${HOSTNAME}
echo "user $USER" > ~/.ssh/config

# samba
cat /etc/samba/smb.conf | grep "\[share\]"
if [ $? == 1 ]; then
dst="/etc/samba/smb.conf.`date +%Y%m%d-%H%M%S`"
backup_file "/etc/samba/smb.conf" "${dst}" 1
sudo bash -c 'cat << EOF >> /etc/samba/smb.conf
[share]
path = ~
public = yes
writable = yes
valid users = samba
create mask = 0644
force create mode = 0644
directory mask = 0755
force directory mode = 0755
available = yes
EOF'
fi

cat << EOF | sudo smbpasswd -a samba
1
EOF
sudo service smbd restart

# repo
curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo -o repo
chmod +x repo
sudo mv repo /usr/bin/

cat ~/.bashrc | grep "tsinghua"
if [ $? == 1 ]; then
cat << EOF >> ~/.bashrc
export REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/git/git-repo'
EOF
fi

## post install manu
echo "===================================================================="
echo
echo
echo "      接下来你需要手动做以下事情        "
echo
echo
echo "===================================================================="
echo "1. 将如下公钥添加到 Gerrit Settings 中:"
cat ~/.ssh/id_rsa.pub
echo
