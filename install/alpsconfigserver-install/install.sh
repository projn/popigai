#!/bin/bash

##########################################################
# 安装alpsmicroservice                                    #
# Author: sunyuecheng                                    #
##########################################################
#全局变量

#当前工作目录
CURRENT_WORK_DIR=$(cd `dirname $0`; pwd)

#应用配置信息
source ${CURRENT_WORK_DIR}/config.properties

##########################################################

function usage()
{
    echo "Usage: install.sh [--help]"
    echo ""
    echo "install alps micro service."
    echo ""
    echo "  --help                  : help"
    echo ""
    echo "  --install-single        : install single."
    echo "  --install-cloud         : install cloud."
    echo "  --create-cloud-git-repo : create cloud git repo."
    echo "  --uninstall             : uninstall."
}

function check_install()
{
    echo "Check install package ..."

    install_package_path=${CURRENT_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}
    check_dir ${install_package_path}
    if [ $? != 0 ]; then
    	echo "Install package ${install_package_path} do not exist."
      return 1
    fi

    service_file_path=${CURRENT_WORK_DIR}/${SOFTWARE_SERVICE_NAME}
    check_file ${service_file_path}
    if [ $? != 0 ]; then
    	echo "Service file ${service_file_path} do not exist."
      return 1
    fi

    echo "Check finish."
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
    echo "Begin install..."
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

    mkdir -p ${SOFTWARE_INSTALL_PATH}
    chmod u=rwx,g=r,o=r ${SOFTWARE_INSTALL_PATH}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_INSTALL_PATH}

    mkdir -p ${SOFTWARE_DATA_PATH}
    chmod u=rwx,g=r,o=r ${SOFTWARE_DATA_PATH}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_DATA_PATH}

    mkdir -p ${SOFTWARE_LOG_PATH}
    chmod u=rwx,g=r,o=r ${SOFTWARE_LOG_PATH}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_LOG_PATH}

    package_dir=${CURRENT_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}
    cp -rf ${package_dir}/* ${SOFTWARE_INSTALL_PATH}/

    chown -R ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_INSTALL_PATH}
    find ${SOFTWARE_INSTALL_PATH} -type d -exec chmod 700 {} \;
    chmod u=rwx,g=rwx,o=r  ${SOFTWARE_INSTALL_PATH}/*.jar
    chmod -R u=rwx,g=rwx,o=r ${SOFTWARE_INSTALL_PATH}/context/

    echo  "Start to config service ..."

    src=SOFTWARE_SERVER_IP
    dst=${SOFTWARE_SERVER_IP}
    sed -i "s#$src#$dst#g" ${SOFTWARE_INSTALL_PATH}/context/bootstrap.properties

    src=SOFTWARE_SERVER_PORT
    dst=${SOFTWARE_SERVER_PORT}
    sed -i "s#$src#$dst#g" ${SOFTWARE_INSTALL_PATH}/context/bootstrap.properties

    src=SOFTWARE_GIT_REMOTE_REPO_URL
    dst=${SOFTWARE_GIT_REMOTE_REPO_URL}
    sed -i "s#$src#$dst#g" ${SOFTWARE_INSTALL_PATH}/context/bootstrap.properties

    src=SOFTWARE_GIT_REMOTE_REPO_USERNAME
    dst=${SOFTWARE_GIT_REMOTE_REPO_USERNAME}
    sed -i "s#$src#$dst#g" ${SOFTWARE_INSTALL_PATH}/context/bootstrap.properties

    src=SOFTWARE_GIT_REMOTE_REPO_PASSWORD
    dst=${SOFTWARE_GIT_REMOTE_REPO_PASSWORD}
    sed -i "s#$src#$dst#g" ${SOFTWARE_INSTALL_PATH}/context/bootstrap.properties

    src=SOFTWARE_GIT_LOCAL_REPO_LABEL
    dst=${SOFTWARE_GIT_LOCAL_REPO_LABEL}
    sed -i "s#$src#$dst#g" ${SOFTWARE_INSTALL_PATH}/context/bootstrap.properties

    src=SOFTWARE_GIT_LOCAL_REPO_DIR
    dst=${SOFTWARE_GIT_LOCAL_REPO_DIR}
    sed -i "s#$src#$dst#g" ${SOFTWARE_INSTALL_PATH}/context/bootstrap.properties

    src=SOFTWARE_ACL_KEY_PATH
    dst=${SOFTWARE_ACL_KEY_PATH}
    sed -i "s#$src#$dst#g" ${SOFTWARE_INSTALL_PATH}/context/bootstrap.properties

    src=SOFTWARE_ACL_KEY_PASSWORD
    dst=${SOFTWARE_ACL_KEY_PASSWORD}
    sed -i "s#$src#$dst#g" ${SOFTWARE_INSTALL_PATH}/context/bootstrap.properties

    src=SOFTWARE_ACL_KEY_ALIAS
    dst=${SOFTWARE_ACL_KEY_ALIAS}
    sed -i "s#$src#$dst#g" ${SOFTWARE_INSTALL_PATH}/context/bootstrap.properties

    src=SOFTWARE_ACL_KEY_SECRET
    dst=${SOFTWARE_ACL_KEY_SECRET}
    sed -i "s#$src#$dst#g" ${SOFTWARE_INSTALL_PATH}/context/bootstrap.properties

    src=SOFTWARE_CONSUL_SERVER_ADDRESS
    dst=${SOFTWARE_CONSUL_SERVER_ADDRESS}
    sed -i "s#$src#$dst#g" ${SOFTWARE_INSTALL_PATH}/context/bootstrap.properties

    src=SOFTWARE_CONSUL_PORT
    dst=${SOFTWARE_CONSUL_PORT}
    sed -i "s#$src#$dst#g" ${SOFTWARE_INSTALL_PATH}/context/bootstrap.properties

    cp ${CURRENT_WORK_DIR}/${SOFTWARE_SERVICE_NAME} /etc/init.d/${SOFTWARE_SERVICE_NAME}

    src=SOFTWARE_INSTALL_PATH
    dst=${SOFTWARE_INSTALL_PATH}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}

    src=SOFTWARE_USER_NAME
    dst=${SOFTWARE_USER_NAME}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}

    src=SOFTWARE_JAR_NAME
    dst=${SOFTWARE_JAR_NAME}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}

	chmod 755 /etc/init.d/${SOFTWARE_SERVICE_NAME}
	chkconfig --add ${SOFTWARE_SERVICE_NAME}

    echo "config service success."

    echo "install success."

    service ${SOFTWARE_SERVICE_NAME} start

    return 0
}

function uninstall()
{
    echo "Uninstall enter ..."

    rm -rf ${SOFTWARE_INSTALL_PATH}
    rm -rf ${SOFTWARE_LOG_PATH}
    rm -rf ${SOFTWARE_DATA_PATH}

    chkconfig --del ${SOFTWARE_SERVICE_NAME}
    rm /etc/init.d/${SOFTWARE_SERVICE_NAME}
    echo "remove service success."

    echo "uninstall success."
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
elif [ "${opt}" == "--uninstall" ]; then
    uninstall
elif [ "${opt}" == "--help" ]; then
    usage
else
    echo "Unknown argument"
fi

