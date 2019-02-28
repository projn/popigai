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
    echo "  --uninstall             : uninstall."
}

function check_install()
{
    install_package_path=${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}
    check_file ${install_package_path}
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

    father_dir=`dirname ${SOFTWARE_LOG_PATH}`
    mkdir -p ${father_dir}
    chmod 755 ${father_dir}
    mkdir -p ${SOFTWARE_LOG_PATH}
    chmod 700 ${SOFTWARE_LOG_PATH}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_LOG_PATH}

    package_path=${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}
    cp -rf ${package_path} ${SOFTWARE_INSTALL_PATH}/

    chown -R ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_INSTALL_PATH}
    chmod 755 ${SOFTWARE_INSTALL_PATH}/${SOFTWARE_SOURCE_PACKAGE_NAME}

    return 0
}

function config()
{
    cp ${CURRENT_WORK_DIR}/${SOFTWARE_SERVICE_NAME} /etc/init.d/${SOFTWARE_SERVICE_NAME}

    src=SOFTWARE_USER_NAME
    dst=${SOFTWARE_USER_NAME}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}

    src=SOFTWARE_PROCESS_NAME
    dst=${JENKINS_PROCESS_NAME}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}

    src=SOFTWARE_BIND_IP
    dst=${JENKINS_BIND_IP}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}

    src=SOFTWARE_PORT
    dst=${JENKINS_PORT}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}

    src=SOFTWARE_INSTALL_PATH
    dst=${SOFTWARE_INSTALL_PATH}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}

    src=SOFTWARE_DATA_PATH
    dst=${SOFTWARE_DATA_PATH}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}

    src=SOFTWARE_LOG_PATH
    dst=${SOFTWARE_LOG_PATH}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}

    chmod 755 /etc/init.d/${SOFTWARE_SERVICE_NAME}
    chkconfig --add ${SOFTWARE_SERVICE_NAME}

    echo "Install success."
}

function package() {
    wget https://mirrors.tuna.tsinghua.edu.cn/jenkins/war-stable/${SOFTWARE_SOURCE_PACKAGE_VERSION}/jenkins.war
}

function uninstall()
{
    rm -rf ${SOFTWARE_INSTALL_PATH}
    rm -rf ${SOFTWARE_LOG_PATH}
    rm -rf ${SOFTWARE_DATA_PATH}

    chkconfig --del ${SOFTWARE_SERVICE_NAME}
    rm /etc/init.d/${SOFTWARE_SERVICE_NAME}

    echo "Uninstall success."

    return 0
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
    config
elif [ "${opt}" == "--uninstall" ]; then
    if [ ! `id -u` = "0" ]; then
        echo "Please run as root user"
        exit 2
    fi
    uninstall
elif [ "${opt}" == "--help" ]; then
    usage
else
    echo "Unknown argument"
fi

