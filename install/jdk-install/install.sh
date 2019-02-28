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
    echo "  --uninstall             : uninstall."
}

function delete_openjdk()
{
    rpm -qa | grep java
    java-1.8.0-openjdk-headless-1.8.0.101-3.b13.el7_2.x86_64
    tzdata-java-2016f-1.el7.noarch
    java-1.8.0-openjdk-1.8.0.101-3.b13.el7_2.x86_64
    javapackages-tools-3.4.1-11.el7.noarch
    java-1.7.0-openjdk-headless-1.7.0.111-2.6.7.2.el7_2.x86_64
    java-1.7.0-openjdk-1.7.0.111-2.6.7.2.el7_2.x86_64

    rpm -e --nodeps java-1.8.0-openjdk-headless-1.8.0.101-3.b13.el7_2.x86_64
    rpm -e --nodeps java-1.8.0-openjdk-1.8.0.101-3.b13.el7_2.x86_64
    rpm -e --nodeps java-1.7.0-openjdk-headless-1.7.0.111-2.6.7.2.el7_2.x86_64
    rpm -e --nodeps java-1.7.0-openjdk-1.7.0.111-2.6.7.2.el7_2.x86_64
}

function check_install()
{
    echo "Check install package ..."

    install_package_path=${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}.tar.gz
    check_file ${install_package_path}
    if [ $? != 0 ]; then
    	echo "Install package ${install_package_path} do not exist."
      return 1
    fi

    install_config_path=${CURRENT_WORK_DIR}/config.properties
    check_file ${install_config_path}
    if [ $? != 0 ]; then
    	echo "Install config ${install_config_path} do not exist."
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

    tar -zxvf ${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}.tar.gz \
        -C ${SOFTWARE_INSTALL_PATH}/

    chmod u=rwx,g=r,o=r ${SOFTWARE_INSTALL_PATH}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_INSTALL_PATH}

    echo "export JAVA_HOME=${SOFTWARE_INSTALL_PATH}/${SOFTWARE_INSTALL_PACKAGE_NAME}">>/etc/profile
    echo 'export JRE_HOME=${JAVA_HOME}/jre'>>/etc/profile
    echo 'export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib:$CLASSPATH'>>/etc/profile
    echo 'export JAVA_PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin'>>/etc/profile
    echo 'export PATH=$PATH:${JAVA_PATH}'>>/etc/profile

    source /etc/profile

    return 0
}

function uninstall()
{
    echo "Uninstall enter ..."
    
    rm -rf ${SOFTWARE_INSTALL_PATH}
    
    echo "Uninstall leave ..."
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

