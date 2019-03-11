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

    install_config_path=${CURRENT_WORK_DIR}/config.properties
    check_file ${install_config_path}
    if [ $? != 0 ]; then
    	echo "Install config ${install_config_path} do not exist."
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

    mkdir -p ${SOFTWARE_INSTALL_PATH}
    chmod u=rwx,g=rx,o=r ${SOFTWARE_INSTALL_PATH}
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_INSTALL_PATH}

    tar -zxvf ${CURRENT_WORK_DIR}/${SOFTWARE_SOURCE_PACKAGE_NAME} \
        -C ${SOFTWARE_INSTALL_PATH}/

    echo "export MAVEN_HOME=${SOFTWARE_INSTALL_PATH}/${SOFTWARE_INSTALL_PACKAGE_NAME}">>/etc/profile
    echo 'export PATH=$PATH:$MAVEN_HOME/bin'>>/etc/profile

    source /etc/profile

    if [ "${MAVEN_INSTALL_NEXUS_SETTING}" == "true" ]; then
        if [ "${SOFTWARE_USER_NAME}" == "root" ]; then
            cp ${CURRENT_WORK_DIR}/settings.xml /${SOFTWARE_USER_NAME}/.m2/settings.xml
            chown -R ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} /${SOFTWARE_USER_NAME}/.m2

            src=MAVEN_INSTALL_NEXUS_HOST
            dst=${MAVEN_INSTALL_NEXUS_HOST}
            sed -i "s#$src#$dst#g" /${SOFTWARE_USER_NAME}/.m2/settings.xml

            src=MAVEN_INSTALL_NEXUS_PORT
            dst=${MAVEN_INSTALL_NEXUS_PORT}
            sed -i "s#$src#$dst#g" /${SOFTWARE_USER_NAME}/.m2/settings.xml

            src=MAVEN_INSTALL_NEXUS_USERNAME
            dst=${MAVEN_INSTALL_NEXUS_USERNAME}
            sed -i "s#$src#$dst#g" /${SOFTWARE_USER_NAME}/.m2/settings.xml

            src=MAVEN_INSTALL_NEXUS_PWD
            dst=${MAVEN_INSTALL_NEXUS_PWD}
            sed -i "s#$src#$dst#g" /${SOFTWARE_USER_NAME}/.m2/settings.xml
        else
            mkdir -p /home/${SOFTWARE_USER_NAME}/.m2/
            cp ${CURRENT_WORK_DIR}/settings.xml /home/${SOFTWARE_USER_NAME}/.m2/settings.xml
            chown -R ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} /home/${SOFTWARE_USER_NAME}/.m2

            src=MAVEN_INSTALL_NEXUS_HOST
            dst=${MAVEN_INSTALL_NEXUS_HOST}
            sed -i "s#$src#$dst#g" /home/${SOFTWARE_USER_NAME}/.m2/settings.xml

            src=MAVEN_INSTALL_NEXUS_PORT
            dst=${MAVEN_INSTALL_NEXUS_PORT}
            sed -i "s#$src#$dst#g" /home/${SOFTWARE_USER_NAME}/.m2/settings.xml

            src=MAVEN_INSTALL_NEXUS_USERNAME
            dst=${MAVEN_INSTALL_NEXUS_USERNAME}
            sed -i "s#$src#$dst#g" /home/${SOFTWARE_USER_NAME}/.m2/settings.xml

            src=MAVEN_INSTALL_NEXUS_PWD
            dst=${MAVEN_INSTALL_NEXUS_PWD}
            sed -i "s#$src#$dst#g" /home/${SOFTWARE_USER_NAME}/.m2/settings.xml
        fi
    fi

    echo "Install success,use cmd 'source /etc/profile' to make it in use."

    return 0
}

function package() {
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
            wget http://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/${SOFTWARE_SOURCE_PACKAGE_VERSION}/binaries/${SOFTWARE_SOURCE_PACKAGE_NAME}
        fi
    fi
}

function uninstall()
{
    rm -rf ${SOFTWARE_INSTALL_PATH}
    
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

