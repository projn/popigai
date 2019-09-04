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
    check_install
    if [ $? != 0 ]; then
        echo "Check install failed,check it please."
        return 1
    fi

    mkdir -p ${SOFTWARE_INSTALL_PATH}

    mkdir -p ${SOFTWARE_DATA_PATH}

    mkdir -p ${SOFTWARE_LOG_PATH}

    package_path=${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}
    tar zxvf ${package_path} -C ${CUR_WORK_DIR}/
    cp -rf ${CUR_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}/* ${SOFTWARE_INSTALL_PATH}

    return 0
}

function config()
{

    sample_config_path=${SOFTWARE_INSTALL_PATH}/conf/zoo_sample.cfg
    config_path=${SOFTWARE_INSTALL_PATH}/conf/zoo.cfg
    cp -rf ${sample_config_path} ${config_path}

    src='/tmp/zookeeper'
    dst=${SOFTWARE_DATA_PATH}
    sed -i "s#$src#$dst#g" ${config_path}

    src=2181
    dst=${ZOOKEEPER_CLIENT_PORT}
    sed -i "s#$src#$dst#g" ${config_path}

    count=1
    for host in ${ZOOKEEPER_CLUSTER_HOST_LIST[@]}
    do
        echo "server.${count}=${host}:2888:3888">>${config_path}
        ((count++))
    done

    echo "${ZOOKEEPER_MYID}">>${SOFTWARE_DATA_PATH}/myid

    log_config_path=${SOFTWARE_INSTALL_PATH}/conf/log4j.properties
    src='zookeeper.log.dir=.'
    dst='zookeeper.log.dir='${SOFTWARE_LOG_PATH}
    sed -i "s#$src#$dst#g" ${log_config_path}

    src='zookeeper.tracelog.dir=.'
    dst='zookeeper.tracelog.dir='${SOFTWARE_DATA_PATH}
    sed -i "s#$src#$dst#g" ${log_config_path}

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
            https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/${SOFTWARE_INSTALL_PACKAGE_NAME}/${SOFTWARE_SOURCE_PACKAGE_NAME}
        fi
    fi
}

function uninstall()
{
    rm -rf ${SOFTWARE_INSTALL_PATH}
    rm -rf ${SOFTWARE_LOG_PATH}
    rm -rf ${SOFTWARE_DATA_PATH}

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