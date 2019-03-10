#!/bin/bash

CURRENT_WORK_DIR=$(cd `dirname $0`; pwd)
source ${CURRENT_WORK_DIR}/config.properties

function usage()
{
    echo "Usage: install.sh [--help]"
    echo ""
    echo "install redis."
    echo ""
    echo "  --help                  : help."
    echo ""
    echo "  --install               : install."
}

function check_install()
{
    return 0
}

function check_user_group()
{
    local tmp=$(cat /etc/group | grep ${1}: | grep -v grep)

    if [ -z "$tmp" ]; then
        return 2
    else
        return 0
    fi
}

function check_user()
{
   if id -u ${1} >/dev/null 2>&1; then
        return 0
    else
        return 2
    fi
}

function check_file()
{
    if [ -f ${1} ]; then
        return 0
    else
        return 2
    fi
}

function check_dir()
{
    if [ -d ${1} ]; then
        return 0
    else
        return 2
    fi
}

function install()
{
    cd /etc/yum.repos.d/
    wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo\

    yum repolist
    yum install -y docker-ce
    mkdir -p /etc/docker
#    rm -rf /etc/docker/daemon.json
#    echo "{"  >> /etc/docker/daemon.json
#    echo '"registry-mirrors": ["https://5q5g7ksn.mirror.aliyuncs.com"]'  >> /etc/docker/daemon.json
#    echo "}"  >> /etc/docker/daemon.json

    systemctl enable docker
    systemctl daemon-reload
    systemctl restart docker

    echo "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"

    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

    chmod +x /usr/local/bin/docker-compose

    echo "Install success."

    return 0
}

if [ ! `id -u` = "0" ]; then
    echo "Please run as root user"
    exit 5
fi

if [ $# -eq 0 ]; then
    usage
    exit
fi

opt=$1

if [ "${opt}" == "--install" ]; then
    install
    if [ $? != 0 ]; then
        echo "Install failed,check it please."
        return 1
    fi
elif [ "${opt}" == "--help" ]; then
    usage
else
    echo "Unknown argument"
fi