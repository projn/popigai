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

    package_path=${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}
    tar zxvf ${package_path} -C ${CUR_WORK_DIR}/
    cp -rf ${CUR_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}/* ${SOFTWARE_INSTALL_PATH}

    return 0
}

function config()
{
    config_path=${SOFTWARE_INSTALL_PATH}/config/server.properties

    src='broker.id=0'
    dst='broker.id='${KAFKA_BROKER_ID}
    sed -i "s#$src#$dst#g" ${config_path}

    src='\#listeners=PLAINTEXT://:9092'
    dst='listeners=PLAINTEXT://'${KAFKA_LISTENER_HOST}':'${KAFKA_LISTENER_PORT}
    sed -i "s#$src#$dst#g" ${config_path}

    src='\#advertised.listeners=PLAINTEXT://your.host.name:9092'
    dst='advertised.listeners=PLAINTEXT://'${KAFKA_LISTENER_HOST}':'${KAFKA_LISTENER_PORT}
    sed -i "s#$src#$dst#g" ${config_path}

    src='log.dirs=/tmp/kafka-logs'
    dst='log.dirs='${SOFTWARE_DATA_PATH}
    sed -i "s#$src#$dst#g" ${config_path}

    src='zookeeper.connect=localhost:2181'
    dst='zookeeper.connect='${ZOOKEEPER_CLUSTER_INFO}
    sed -i "s#$src#$dst#g" ${config_path}

    log_config_path=${SOFTWARE_INSTALL_PATH}/bin/kafka-run-class.sh
    sed -i "175iLOG_DIR=${SOFTWARE_LOG_PATH}" ${log_config_path}

    echo "Install success."
}

function package()
{
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
            wget https://www.apache.org/dyn/closer.cgi?path=/kafka/${SOFTWARE_SOURCE_PACKAGE_VERSION}/${SOFTWARE_SOURCE_PACKAGE_NAME}
        fi
    fi
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