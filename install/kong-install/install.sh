#!/bin/bash

CURRENT_WORK_DIR=$(cd `dirname $0`; pwd)
source ${CURRENT_WORK_DIR}/config.properties

function usage()
{
    echo "Usage: install.sh [--help]"
    echo ""
    echo "install kong."
    echo ""
    echo "  --help                  : help."
    echo ""
    echo "  --install               : install."
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

function install_postgresql() {
    yum install ${KONG_POSTGRES_RPM_URL}

    yum install postgresql11-server

    /usr/pgsql-11/bin/postgresql-11-setup initdb
    systemctl enable postgresql-11
    systemctl start postgresql-11

groupadd postgres
useradd -g postgres postgres
passwd postgres

/etc/rc.d/init.d/postgresql
}

function install()
{
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

    cd /etc/yum.repos.d/

    rm -rf kong.repo
    echo "[kong]" >> /etc/yum.repos.d/kong.repo
    echo "name=Kong Repo" >> /etc/yum.repos.d/kong.repo
    echo "baseurl=https://kong.bintray.com/kong-community-edition-rpm/centos/7" >> /etc/yum.repos.d/kong.repo
    echo "enables=1" >> /etc/yum.repos.d/kong.repo

    yum repolist
    yum install -y epel-release
    yum install -y kong-community-edition.noarch --nogpgcheck

    return 0
}

function config()
{
    cp ${CURRENT_WORK_DIR}/${SOFTWARE_SERVICE_NAME} /etc/init.d/${SOFTWARE_SERVICE_NAME}

    chown -R ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_INSTALL_PATH}
    chmod -R u=rwx,g=rwx,o=r ${SOFTWARE_INSTALL_PATH}

    src=SOFTWARE_USER_NAME
    dst=${SOFTWARE_USER_NAME}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}

    src=SOFTWARE_INSTALL_PATH
    dst=${SOFTWARE_INSTALL_PATH}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}

    config_path=${SOFTWARE_INSTALL_PATH}/kong.config
    cp /etc/kong/kong.conf.default ${config_path}

    sed -i "s:#prefix = /usr/local/kong/:prefix = ${SOFTWARE_LOG_PATH}/:g" ${config_path}
    sed -i "s/#database = postgres/database = postgres/g" ${config_path}
    sed -i "s/#pg_host = 127.0.0.1/pg_host = ${KONG_POSTGRES_IP}/g" ${config_path}
    sed -i "s/#pg_port = 5432/pg_port = ${KONG_POSTGRES_PORT}/g" ${config_path}
    sed -i "s/#pg_user = kong/pg_user = ${KONG_POSTGRES_USER}/g" ${config_path}
    sed -i "s/#pg_password =/pg_password = ${KONG_POSTGRES_PASSWORD}/g" ${config_path}
    sed -i "s/#pg_database = kong/pg_database = ${KONG_POSTGRES_DATABASE_NAME}/g" ${config_path}

    sed -i "s/#db_update_frequency = 5/db_update_frequency = ${KONG_DB_UPDATE_FREQUENCY_SECOND}/g" ${config_path}

    sed -i "s/#admin_listen = 127.0.0.1:8001, 127.0.0.1:8444 ssl/admin_listen = ${KONG_ADMIN_LISTEN_IP}:8001, ${KONG_ADMIN_LISTEN_IP}:8444 ssl/g" ${config_path}

    chmod 755 /etc/init.d/${SOFTWARE_SERVICE_NAME}
    chkconfig --add ${SOFTWARE_SERVICE_NAME}

    echo "Install success,please create postgresql schame by this cmd:
        CREATE USER kong; CREATE DATABASE kong OWNER kong;
        and then run cmd:
        kong migrations bootstrap -c ${config_path}"
}

function uninstall()
{
    rm -rf ${SOFTWARE_INSTALL_PATH}
    rm -rf ${SOFTWARE_LOG_PATH}
    rm -rf ${SOFTWARE_DATA_PATH}

    chkconfig --del ${SOFTWARE_SERVICE_NAME}
    rm /etc/init.d/${SOFTWARE_SERVICE_NAME}

    kong stop
    rpm -e --nodeps kong-community-edition.noarch

    echo "Uninstall success."
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
    config
elif [ "${opt}" == "--uninstall" ]; then
    uninstall
elif [ "${opt}" == "--help" ]; then
    usage
else
    echo "Unknown argument"
fi