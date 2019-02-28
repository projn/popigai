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
    echo "  --package               : package."
    echo "  --install               : install."
}

function check_install()
{
    install_package_path=${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}
    check_file ${install_package_path}
    if [ $? != 0 ]; then
    	echo "Install package ${install_package_path} do not exist."
      return 1
    fi
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
    check_install
    if [ $? != 0 ]; then
        echo "Check install failed,check it please."
        return 1
    fi

    check_user_group ${SOFTWARE_USER_GROUP}
    if [ $? != 0 ]; then
    	groupadd ${SOFTWARE_USER_GROUP}

    	echo "Add user group ${SOFTWARE_USER_GROUP} success."
    fi

    check_user ${SOFTWARE_USER_NAME}
    if [ $? != 0 ]; then
    	useradd -g ${SOFTWARE_USER_GROUP} -m ${SOFTWARE_USER_NAME}
        usermod -L ${SOFTWARE_USER_NAME}

        echo "Add user ${SOFTWARE_USER_NAME} success."
    fi

    cd /etc/yum.repos.d/
    wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo\

    yum repolist
    yum install -y docker-ce
    mkdir -p /etc/docker
    echo "{"  >> /etc/docker/daemon.json
    echo '"registry-mirrors": ["https://5q5g7ksn.mirror.aliyuncs.com"]'  >> /etc/docker/daemon.json
    echo "}"  >> /etc/docker/daemon.json

    systemctl enable docker
    systemctl daemon-reload
    systemctl restart docker

    echo "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"

    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

    chmod +x /usr/local/bin/docker-compose

    father_dir=`dirname ${SOFTWARE_INSTALL_PATH}`
    mkdir -p ${father_dir}
    chmod 755 ${father_dir}
    mkdir -p ${SOFTWARE_INSTALL_PATH}
    chmod 700 ${SOFTWARE_INSTALL_PATH}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_INSTALL_PATH}

    father_dir=`dirname ${SOFTWARE_DATA_PATH}`
    mkdir -p ${father_dir}
    chmod 755 ${father_dir}
    mkdir -p ${SOFTWARE_DATA_PATH}
    chmod 700 ${SOFTWARE_DATA_PATH}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_DATA_PATH}

    package_path=${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}
    tar zxvf ${package_path} -C ${CUR_WORK_DIR}/
    cp -rf ${CUR_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}/* ${SOFTWARE_INSTALL_PATH}

    if [ "${HARBOR_SSH_FLAG}" == "true" ]; then
        cd ${SOFTWARE_INSTALL_PATH}
        openssl req -newkey rsa:4096 -nodes -sha256 -keyout ca.key -x509 -days 365 -out ca.crt
    fi

    chown -R ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_INSTALL_PATH}
    chmod -R u=rwx,g=rwx,o=r ${SOFTWARE_INSTALL_PATH}

    return 0
}

function config()
{
    config_path=${SOFTWARE_INSTALL_PATH}/harbor.cfg

    src='reg.mydomain.com'
    dst=${HARBOR_HOST}
    sed -i "s#$src#$dst#g" ${config_path}

    if [ "${HARBOR_SSH_FLAG}" == "true" ]; then
        src='ui_url_protocol = http'
        dst='ui_url_protocol = https'
        sed -i "s#$src#$dst#g" ${config_path}

        src='ssl_cert = /data/cert/server.crt'
        dst='ssl_cert = '${SOFTWARE_INSTALL_PATH}'/ca.crt'
        sed -i "s#$src#$dst#g" ${config_path}

        src='ssl_cert_key = /data/cert/server.key'
        dst='ssl_cert_key = '${SOFTWARE_INSTALL_PATH}'/ca.key'
        sed -i "s#$src#$dst#g" ${config_path}

        src='secretkey_path = /data'
        dst='secretkey_path = '${SOFTWARE_DATA_PATH}
        sed -i "s#$src#$dst#g" ${config_path}
    fi

    sh ${SOFTWARE_INSTALL_PATH}/install.sh --with-clair --with-chartmuseum

    echo "Install success,use cmd 'docker-compose stop/start' to manage status in install path."
}

function package() {
    wget https://storage.googleapis.com/harbor-releases/release-${SOFTWARE_SOURCE_PACKAGE_VERSION}/${SOFTWARE_SOURCE_PACKAGE_NAME}
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
        return 2
    fi

    config
elif [ "${opt}" == "--help" ]; then
    usage
else
    echo "Unknown argument"
fi