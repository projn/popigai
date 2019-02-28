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
    echo "  --install-cluster-node  : install cluster node."
    echo "  --install-cluster       : install cluster."
    echo "  --install-master-node   : install master node."
    echo "  --install-slave-node    : install slave node."
    echo "  --install-sentinel-node : install sentinel node."
    echo "  --uninstall             : uninstall."
}

function check_install()
{
    echo "Check install package ..."

    install_package_path=${CURRENT_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}/bin
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

function install_redis()
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
    chmod -R u=rwx,g=rwx,o=r ${SOFTWARE_INSTALL_PATH}/bin/

    return 0
}

function config_redis_cluster_node()
{
    for port in ${REDIS_NODE_PORT_LIST[@]}
    do
        config_dir=${SOFTWARE_INSTALL_PATH}/conf/${port}
        mkdir -p ${config_dir}
        chmod u=rwx,g=r,o=r ${config_dir}
        chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${config_dir}
        cp ${SOFTWARE_INSTALL_PATH}/conf/redis.conf ${config_dir}/
        chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${config_dir}/redis.conf

        log_dir=${SOFTWARE_LOG_PATH}/${port}/redis.log
        mkdir -p ${log_dir}
        chmod u=rwx,g=r,o=r ${log_dir}
        chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${log_dir}

        log_path=${SOFTWARE_LOG_PATH}/${port}/redis.log
        pid_file_path=${SOFTWARE_LOG_PATH}/${port}/redis.pid

        data_dir=${SOFTWARE_DATA_PATH}/${port}
        mkdir -p ${data_dir}
        chmod u=rwx,g=r,o=r ${data_dir}
        chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${data_dir}

        log_path_sed=$(echo ${log_path} |sed -e 's/\//\\\//g' )
        data_dir_sed=$(echo ${data_dir} |sed -e 's/\//\\\//g' )

        sed -i "s#bind[ ]127.0.0.1#bind ${REDIS_BIND_IP}#g" ${config_dir}/redis.conf
        sed -i "s#port[ ]6379#port ${port}#g" ${config_dir}/redis.conf
        sed -i "s#logfile[ ]""#logfile ${log_path_sed}#g" ${config_dir}/redis.conf
        sed -i "s#pidfile[ ]/var/run/redis_6379.pid#pidfile ${pid_file_path}#g" ${config_dir}/redis.conf
        sed -i "s#dir[ ]./#dir ${data_dir_sed}#g" ${config_dir}/redis.conf
        sed -i "s#daemonize[ ]no#daemonize yes#g" ${config_dir}/redis.conf

        sed -i "s#\#[ ]cluster-enabled[ ]yes#cluster-enabled yes#g" ${config_dir}/redis.conf

        echo "Start to config service ..."
        cp ${CURRENT_WORK_DIR}/${SOFTWARE_SERVICE_NAME} /etc/init.d/${SOFTWARE_SERVICE_NAME}-${port}

        src=SOFTWARE_INSTALL_PATH
        dst=${SOFTWARE_INSTALL_PATH}
        sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}-${port}

        src=SOFTWARE_USER_NAME
        dst=${SOFTWARE_USER_NAME}
        sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}-${port}

        chmod 755 /etc/init.d/${SOFTWARE_SERVICE_NAME}-${port}
        chkconfig --add ${SOFTWARE_SERVICE_NAME}-${port}

        echo "Config service success."
    done
}

function config_redis_cluster()
{
    #yum -y install ruby ruby-devel rubygems rpm-build
    #gem install redis

    cd ${SOFTWARE_INSTALL_PATH}/bin
    ./redis-trib.rb create --replicas 1 ${REDIS_CLUSTER_CONFIG}
}

function config_redis_master_node()
{
    config_dir=${SOFTWARE_INSTALL_PATH}/conf/${REDIS_MASTER_PORT}
    mkdir -p ${config_dir}
    chmod u=rwx,g=r,o=r ${config_dir}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${config_dir}
    cp ${SOFTWARE_INSTALL_PATH}/conf/redis.conf ${config_dir}/
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${config_dir}/redis.conf

    log_dir=${SOFTWARE_LOG_PATH}/${REDIS_MASTER_PORT}/redis.log
    mkdir -p ${log_dir}
    chmod u=rwx,g=r,o=r ${log_dir}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${log_dir}

    log_path=${SOFTWARE_LOG_PATH}/${REDIS_MASTER_PORT}/redis.log
    pid_file_path=${SOFTWARE_LOG_PATH}/${REDIS_MASTER_PORT}/redis.pid

    data_dir=${SOFTWARE_DATA_PATH}/${REDIS_MASTER_PORT}
    mkdir -p ${data_dir}
    chmod u=rwx,g=r,o=r ${data_dir}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${data_dir}

    log_path_sed=$(echo ${log_path} |sed -e 's/\//\\\//g' )
    data_dir_sed=$(echo ${data_dir} |sed -e 's/\//\\\//g' )

    sed -i "s#bind[ ]127.0.0.1#bind ${REDIS_BIND_IP}#g" ${config_dir}/redis.conf
    sed -i "s#port[ ]6379#port ${REDIS_MASTER_PORT}#g" ${config_dir}/redis.conf
    sed -i "s#logfile[ ]""#logfile ${log_path_sed}#g" ${config_dir}/redis.conf
    sed -i "s#pidfile[ ]/var/run/redis_6379.pid#pidfile ${pid_file_path}#g" ${config_dir}/redis.conf
    sed -i "s#dir[ ]./#dir ${data_dir_sed}#g" ${config_dir}/redis.conf
    sed -i "s#daemonize[ ]no#daemonize yes#g" ${config_dir}/redis.conf

    echo  "Start to config service ..."
    cp ${CURRENT_WORK_DIR}/${SOFTWARE_SERVICE_NAME} /etc/init.d/${SOFTWARE_SERVICE_NAME}-${REDIS_MASTER_PORT}

    src=SOFTWARE_INSTALL_PATH
    dst=${SOFTWARE_INSTALL_PATH}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}-${REDIS_MASTER_PORT}

    src=SOFTWARE_USER_NAME
    dst=${SOFTWARE_USER_NAME}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}-${REDIS_MASTER_PORT}

    chmod 755 /etc/init.d/${SOFTWARE_SERVICE_NAME}-${REDIS_MASTER_PORT}
    chkconfig --add ${SOFTWARE_SERVICE_NAME}-${REDIS_MASTER_PORT}

    echo "Config service success."
}

function config_redis_slave_node()
{
    for port in ${REDIS_NODE_PORT_LIST[@]}
    do
        config_dir=${SOFTWARE_INSTALL_PATH}/conf/${port}
        mkdir -p ${config_dir}
        chmod u=rwx,g=r,o=r ${config_dir}
        chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${config_dir}
        cp ${SOFTWARE_INSTALL_PATH}/conf/redis.conf ${config_dir}/
        chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${config_dir}/redis.conf

        log_dir=${SOFTWARE_LOG_PATH}/${port}/redis.log
        mkdir -p ${log_dir}
        chmod u=rwx,g=r,o=r ${log_dir}
        chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${log_dir}

        log_path=${SOFTWARE_LOG_PATH}/${port}/redis.log
        pid_file_path=${SOFTWARE_LOG_PATH}/${port}/redis.pid

        data_dir=${SOFTWARE_DATA_PATH}/${port}
        mkdir -p ${data_dir}
        chmod u=rwx,g=r,o=r ${data_dir}
        chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${data_dir}

        log_path_sed=$(echo ${log_path} |sed -e 's/\//\\\//g' )
        data_dir_sed=$(echo ${data_dir} |sed -e 's/\//\\\//g' )

        sed -i "s#bind[ ]127.0.0.1#bind ${REDIS_BIND_IP}#g" ${config_dir}/redis.conf
        sed -i "s#port[ ]6379#port ${port}#g" ${config_dir}/redis.conf
        sed -i "s#logfile[ ]""#logfile ${log_path_sed}#g" ${config_dir}/redis.conf
        sed -i "s#pidfile[ ]/var/run/redis_6379.pid#pidfile ${pid_file_path}#g" ${config_dir}/redis.conf
        sed -i "s#dir[ ]./#dir ${data_dir_sed}#g" ${config_dir}/redis.conf
        sed -i "s#daemonize[ ]no#daemonize yes#g" ${config_dir}/redis.conf

        master_info='replicaof '${REDIS_MASTER_IP}' '${REDIS_MASTER_PORT}
        sed -i "s#\# replicaof[ ]<masterip>[ ]<masterport>#replicaof ${REDIS_MASTER_IP} ${REDIS_MASTER_PORT}#g" ${config_dir}/redis.conf

        echo  "Start to config service ..."
        cp ${CURRENT_WORK_DIR}/${SOFTWARE_SERVICE_NAME} /etc/init.d/${SOFTWARE_SERVICE_NAME}-${port}

        src=SOFTWARE_INSTALL_PATH
        dst=${SOFTWARE_INSTALL_PATH}
        sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}-${port}

        src=SOFTWARE_USER_NAME
        dst=${SOFTWARE_USER_NAME}
        sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}-${port}

        chmod 755 /etc/init.d/${SOFTWARE_SERVICE_NAME}-${port}
        chkconfig --add ${SOFTWARE_SERVICE_NAME}-${port}

        echo "Config service success."
    done
}

function config_redis_sentinel_node()
{
    config_dir=${SOFTWARE_INSTALL_PATH}/conf/${REDIS_SENTINEL_PORT}
    mkdir -p ${config_dir}
    chmod u=rwx,g=r,o=r ${config_dir}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${config_dir}
    cp ${SOFTWARE_INSTALL_PATH}/conf/sentinel.conf ${config_dir}/
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${config_dir}/sentinel.conf

    log_dir=${SOFTWARE_LOG_PATH}/${REDIS_SENTINEL_PORT}/sentinel.log
    mkdir -p ${log_dir}
    chmod u=rwx,g=r,o=r ${log_dir}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${log_dir}

    log_path=${SOFTWARE_LOG_PATH}/${REDIS_SENTINEL_PORT}/sentinel.log
    pid_file_path=${SOFTWARE_LOG_PATH}/${REDIS_SENTINEL_PORT}/sentinel.pid

    data_dir=${SOFTWARE_DATA_PATH}/${REDIS_SENTINEL_PORT}
    mkdir -p ${data_dir}
    chmod u=rwx,g=r,o=r ${data_dir}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${data_dir}

    log_path_sed=$(echo ${log_path} |sed -e 's/\//\\\//g' )
    data_dir_sed=$(echo ${data_dir} |sed -e 's/\//\\\//g' )

    sed -i "s#port[ ]26379#port ${REDIS_SENTINEL_PORT}#g" ${config_dir}/sentinel.conf
    sed -i "s#logfile[ ]""#logfile ${log_path_sed}#g" ${config_dir}/sentinel.conf
    sed -i "s#pidfile[ ]/var/run/redis-sentinel.pid#${pid_file_path}#g" ${config_dir}/sentinel.conf
    sed -i "s#dir[ ]/tmp#dir ${data_dir_sed}#g" ${config_dir}/sentinel.conf
    sed -i "s#daemonize[ ]no#daemonize yes#g" ${config_dir}/sentinel.conf

    sed -i "s#sentinel[ ]monitor[ ]mymaster[ ]127.0.0.1[ ]6379[ ]2#sentinel monitor mymaster ${REDIS_SENTINEL_IP} ${REDIS_SENTINEL_PORT} 1#g" ${config_dir}/sentinel.conf

    echo  "Start to config service ..."
    cp ${CURRENT_WORK_DIR}/${SOFTWARE_SERVICE_NAME} /etc/init.d/${SOFTWARE_SERVICE_NAME}-${REDIS_SENTINEL_PORT}

    src=SOFTWARE_INSTALL_PATH
    dst=${SOFTWARE_INSTALL_PATH}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}-${REDIS_SENTINEL_PORT}

    src=SOFTWARE_USER_NAME
    dst=${SOFTWARE_USER_NAME}
    sed -i "s#$src#$dst#g" /etc/init.d/${SOFTWARE_SERVICE_NAME}-${REDIS_SENTINEL_PORT}

    chmod 755 /etc/init.d/${SOFTWARE_SERVICE_NAME}-${REDIS_SENTINEL_PORT}
    chkconfig --add ${SOFTWARE_SERVICE_NAME}-${REDIS_SENTINEL_PORT}

    echo "Config service success."

    #systemctl stop firewalld
    #systemctl disable firewalld
}

function package()
{
    wget http://120.52.51.19/download.redis.io/releases/${SOFTWARE_SOURCE_PACKAGE_NAME}.tar.gz

    tar -zxvf ${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}.tar.gz \
        -C ${CURRENT_WORK_DIR}/
    cd ${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}
    make && make intall
    cd ../
    mkdir ${CURRENT_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}

    mkdir ${CURRENT_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}/bin
    cp ${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}/src/redis-* \
        ${CURRENT_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}/bin
    rm -rf ${CURRENT_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}/bin/*.o \
        ${CURRENT_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}/bin/*.c

    mkdir ${CURRENT_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}/conf
    cp ${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}/redis.conf \
        ${CURRENT_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}/conf
    cp ${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME}/sentinel.conf \
        ${CURRENT_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}/conf

    #tar zcvf  ${CURRENT_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}.tar.gz
    # ./${CURRENT_WORK_DIR}/${SOFTWARE_INSTALL_PACKAGE_NAME}
}

function uninstall()
{
    echo "Uninstall enter ..."
    
    rm -rf ${SOFTWARE_INSTALL_PATH}
    rm -rf ${SOFTWARE_LOG_PATH}
    rm -rf ${SOFTWARE_DATA_PATH}

    for port in ${REDIS_NODE_PORT_LIST[@]}
    do
        chkconfig --del ${SOFTWARE_SERVICE_NAME}-${port}
    done
    chkconfig --del ${SOFTWARE_SERVICE_NAME}-${REDIS_MASTER_PORT}
    chkconfig --del ${SOFTWARE_SERVICE_NAME}-${REDIS_SENTINEL_PORT}
    rm /etc/init.d/${SOFTWARE_SERVICE_NAME}-*
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

if [ "${opt}" == "--package" ]; then
    package
elif [ "${opt}" == "--install-cluster-node" ]; then
    install_redis
    if [ $? != 0 ]; then
        echo "Install failed,check it please."
    else
        config_redis_cluster_node
    fi
elif [ "${opt}" == "--install-cluster" ]; then
    config_redis_cluster
elif [ "${opt}" == "--install-master-node" ]; then
    install_redis
    if [ $? != 0 ]; then
        echo "Install failed,check it please."
    else
        config_redis_master_node
    fi
elif [ "${opt}" == "--install-slave-node" ]; then
    install_redis
    if [ $? != 0 ]; then
        echo "Install failed,check it please."
    else
        config_redis_slave_node
    fi
elif [ "${opt}" == "--install-sentinel-node" ]; then
    install_redis
    if [ $? != 0 ]; then
        echo "Install failed,check it please."
    else
        config_redis_sentinel_node
    fi
elif [ "${opt}" == "--uninstall" ]; then
    uninstall
elif [ "${opt}" == "--help" ]; then
    usage
else
    echo "Unknown argument"
fi

