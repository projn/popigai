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

    if [ "$DOCKER_REPO_MIRROR_URL" != "" ] || ["$DOCKER_HARBOR_INSECURE_ADDRESS" !="" ]; then
        mkdir -p /etc/docker
        rm -rf /etc/docker/daemon.json
        echo "{"  >> /etc/docker/daemon.json
        if [ "$DOCKER_REPO_MIRROR_URL" != "" ]; then
            echo '"registry-mirrors": ["'${DOCKER_REPO_MIRROR_URL}'"]'  >> /etc/docker/daemon.json
        fi
        if [ "$DOCKER_HARBOR_INSECURE_ADDRESS" != "" ]; then
            echo ','  >> /etc/docker/daemon.json
            echo '"insecure-registries": ["'${DOCKER_HARBOR_INSECURE_ADDRESS}'"]'  >> /etc/docker/daemon.json
        fi
        echo "}"  >> /etc/docker/daemon.json
        systemctl daemon-reload
        systemctl restart docker
    fi

    systemctl enable docker

    cp -f ${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME} /usr/local/bin/docker-compose

    chmod +x /usr/local/bin/docker-compose

    echo "Install success."

    return 0
}

function package() {
    install_package_path=${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}
    check_file ${install_package_path}
    if [ $? == 0 ]; then
    	echo "Package file ${install_package_path} exists."
        return 0
    else
        install_package_path=${PACKAGE_REPO_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}
        check_file ${install_package_path}
        if [ $? == 0 ]; then
            cp -rf ${install_package_path} ./
        else
            echo "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
            curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o ./${SOFTWARE_SOURCE_PACKAGE_NAME}
        fi
    fi

}

if [ $# -eq 0 ]; then
    usage
    exit
fi

opt=$1

if [ "${opt}" == "--package" ]; then
    package
elif [ "${opt}" == "--install" ]; then
    if [ ! `id -u` = "0" ]; then
        echo "Please run as root user"
        exit 2
    fi
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