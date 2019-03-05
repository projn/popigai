#!/bin/bash

CURRENT_WORK_DIR=$(cd `dirname $0`; pwd)
source ${CURRENT_WORK_DIR}/config.properties

function usage()
{
    echo "Usage: install.sh [--help]"
    echo ""
    echo "install postgresql."
    echo ""
    echo "  --help                  : help."
    echo ""
    echo "  --install               : install."
    echo "  --uninstall             : uninstall."
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

    father_dir=`dirname ${SOFTWARE_DATA_PATH}`
    mkdir -p ${father_dir}
    chmod 755 ${father_dir}
    mkdir -p ${SOFTWARE_DATA_PATH}
    chmod 755 ${SOFTWARE_DATA_PATH}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_DATA_PATH}

    father_dir=`dirname ${SOFTWARE_LOG_PATH}`
    mkdir -p ${father_dir}
    chmod 755 ${father_dir}
    mkdir -p ${SOFTWARE_LOG_PATH}
    chmod 700 ${SOFTWARE_LOG_PATH}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_LOG_PATH}

    # install the yum repo
    yum install ${POSTGRES_RPM_URL}

    yum install postgresql11
    yum install postgresql11-server

    return 0
}

function config()
{
    # Include the default config:
    echo ".include /lib/systemd/system/postgresql-11.service" >> /etc/systemd/system/postgresql-11.service

    echo "[Service]" >> /etc/systemd/system/postgresql-11.service

    echo "Environment=PGDATA=${SOFTWARE_DATA_PATH}" >> /etc/systemd/system/postgresql-11.service
    systemctl daemon-reload

    # init the postgresql
    /usr/pgsql-11/bin/postgresql-11-setup initdb postgresql-11
    sleep 1

    cd ${SOFTWARE_DATA_PATH}
    echo "host all  all    0.0.0.0/0  md5" >> pg_hba.conf
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" postgresql.conf
    sed -i "s/#port = 5432/port = ${POSTGES_PORT}/g" postgresql.conf
    sed -i "s#log_directory = 'log'#log_directory = '${SOFTWARE_LOG_PATH}'#g" postgresql.conf

    # if you want to listen 1.1.1.1
    # echo "listen_addresses = '1.1.1.1'" >> postgresql.conf 

    cp ${CURRENT_WORK_DIR}/${SOFTWARE_SERVICE_NAME} /etc/init.d/${SOFTWARE_SERVICE_NAME}

    src=SOFTWARE_USER_NAME
    dst=${SOFTWARE_USER_NAME}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}

    chmod 755 /etc/init.d/${SOFTWARE_SERVICE_NAME}
    chkconfig --add ${SOFTWARE_SERVICE_NAME}

    systemctl enable postgresql-11
    systemctl start postgresql-11

    echo "Install success!
        If the firewall is open, add postgresql service with cmd:
        firewall-cmd --add-service=postgresql --permanent;
        and then reload the firewall with cmd:
        firewall-cmd --reload.
        Login postgresql localhost with the cmd:
        su - postgres, 
        and then with cmd: psql"
}

function uninstall()
{

    chkconfig --del ${SOFTWARE_SERVICE_NAME}
    rm /etc/init.d/${SOFTWARE_SERVICE_NAME}

    systemctl stop postgresql
    rpm -e --nodeps postgresql11-server-11.2-2PGDG.rhel7.x86_64
    rpm -e --nodeps postgresql11-11.2-2PGDG.rhel7.x86_64
    rpm -e --nodeps postgresql11-libs-11.2-2PGDG.rhel7.x86_64

    rm -rf ${SOFTWARE_LOG_PATH}
    rm -rf ${SOFTWARE_DATA_PATH}
    rm -rf /var/lib/pgsql/
    rm -rf /lib/systemd/system/postgresql-11.service
    rm -rf /etc/systemd/system/postgresql-11.service

    echo "Uninstall success."
    return 0
}

if [ $# -eq 0 ]; then
    usage
    exit
fi

opt=$1

if [ "${opt}" == "--install" ]; then
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