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

    yum install -y git
    useradd git
    echo "${GIT_USER_PASSWORD}" | passwd --stdin git
    cd /home/git
    mkdir -p ./repository
    chown -R git:git repository
    chsh -s $(command -v git-shell) git
    echo "Install success,
        use cmd 'mkdir -p repository/sample.git; git init --bare repository/sample.git' to add a repository named sample,
        and change mod by cmd 'chown -R git:git repository/'."
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
    if [ $? != 0 ]; then
        echo "Install failed,check it please."
        return 1
    fi
elif [ "${opt}" == "--uninstall" ]; then
    uninstall
elif [ "${opt}" == "--help" ]; then
    usage
else
    echo "Unknown argument"
fi

