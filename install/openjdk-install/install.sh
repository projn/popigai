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

function check_install()
{
    echo "Check install package ..."

    delete_openjdk
    
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

    yum install ${SOFTWARE_SOURCE_PACKAGE_NAME} -y

    return 0
}

function delete_openjdk()
{
    result=`rpm -qa | grep java-1.`

    for i in ${result[@]}
    do
        echo "remove package "$i
        rpm -e --nodeps $i
    done
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
    delete_openjdk
elif [ "${opt}" == "--help" ]; then
    usage
else
    echo "Unknown argument"
fi

