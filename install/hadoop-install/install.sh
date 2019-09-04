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
    uninstall
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

    # 192.168.37.170           # 192.168.37.170           # 192.168.37.170
    # zookeeper                # zookeeper                # zookeeper
    #
    # journalnode              # journalnode              # journalnode
    # namenode                 # namenode                 #
    # zkfc                     # zkfc                     #
    # datanode                 # datanode                 # datanode
    #
    #                          # resourcemanager          # resourcemanager
    # nodemanager              # nodemanager              # nodemanager
    #


    hostnamectl set-hostname bigdata1.projn.com
    hostnamectl set-hostname bigdata2.projn.com
    hostnamectl set-hostname bigdata3.projn.com

    vi /etc/hosts

    192.168.37.170  bigdata1.projn.com bigdata1
192.168.37.171  bigdata2.projn.com bigdata2
192.168.37.172  bigdata3.projn.com bigdata3


    # 配置免密码登陆
    # master-1 生成ssh密钥对

    #ssh-keygen
    # 三次回车后 密钥生成完成
    #cat ~/.ssh/id_rsa.pub
    # 复制该公钥 并分别登陆到master-1 master-2 master-3的root用户，将它令起一行粘贴到 ~/.ssh/authorized_keys文件中 包括master-1自己

    systemctl stop firewalld.service
    systemctl disable firewalld.service

cd bigdata/
tar -zxvf hadoop-2.9.2.tar.gz
tar -zxvf spark-2.4.3-bin-hadoop2.7.tgz
mkdir /opt/software
mv spark-2.4.3-bin-hadoop2.7 /opt/software/spark
mv hadoop-2.9.2 /opt/software/hadoop


vi /etc/profile

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-0.el7_6.x86_64

#hadoop config
export HADOOP_HOME=/opt/software/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_LOG_DIR=/var/log/hadoop
export YARN_HOME=$HADOOP_HOME
export YARN_CONF_DIR=$HADOOP_CONF_DIR

#spark config
export SPARK_HOME=/opt/software/spark
export SPARK_CONF_DIR=$SPARK_HOME/conf

#zookeeper config
export ZOOKEEPER_HOME=/opt/software/zookeeper

export PATH=$SPARK_HOME/bin:$SPARK_HOME/sbin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$ZOOKEEPER_HOME/bin:$PATH

source /etc/profile

mkdir -p /opt/datastore/hadoop

vi hadoop-env.sh

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-0.el7_6.x86_64


vi core-site.xml

<configuration>
    <!-- 指定hdfs的nameservice为ns -->
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://ns/</value>
    </property>

    <!-- 指定hadoop临时目录 -->
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/opt/datastore/hadoop/</value>
    </property>

    <!-- 指定zookeeper地址 -->
    <property>
        <name>ha.zookeeper.quorum</name>
        <value>bigdata1:2181,bigdata2:2181,bigdata3:2181</value>
    </property>

    <!-- hadoop链接zookeeper的超时时长设置 -->
    <property>
        <name>ha.zookeeper.session-timeout.ms</name>
        <value>1000</value>
        <description>ms</description>
    </property>
</configuration>

vi hdfs-site.xml

<configuration>

    <!-- 指定副本数 -->
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>

    <!-- 配置namenode和datanode的工作目录-数据存储目录 -->
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/opt/datastore/hadoop/dfs/name</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/opt/datastore/hadoop/dfs/data</value>
    </property>

    <!-- 启用webhdfs -->
    <property>
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
    </property>

    <!--指定hdfs的nameservice为ns,需要和core-site.xml中的保持一致
        dfs.ha.namenodes.[nameservice id]为在nameservice中的每一个NameNode设置唯一标示符.
        配置一个逗号分隔的NameNode ID列表.这将是被DataNode识别为所有的NameNode.
        例如,如果使用"ns"作为nameservice ID,并且使用"nn1"和"nn2"作为NameNodes标示符
    -->
    <property>
        <name>dfs.nameservices</name>
        <value>ns</value>
    </property>

    <!-- ns下面有两个NameNode,分别是nn1,nn2 -->
    <property>
        <name>dfs.ha.namenodes.ns</name>
        <value>nn1,nn2</value>
    </property>

    <!-- nn1的RPC通信地址 -->
    <property>
        <name>dfs.namenode.rpc-address.ns.nn1</name>
        <value>bigdata1:9000</value>
    </property>

    <!-- nn1的http通信地址 -->
    <property>
        <name>dfs.namenode.http-address.ns.nn1</name>
        <value>bigdata1:50070</value>
    </property>

    <!-- nn2的RPC通信地址 -->
    <property>
        <name>dfs.namenode.rpc-address.ns.nn2</name>
        <value>bigdata2:9000</value>
    </property>

    <!-- nn2的http通信地址 -->
    <property>
        <name>dfs.namenode.http-address.ns.nn2</name>
        <value>bigdata2:50070</value>
    </property>

    <!-- 指定NameNode的edits元数据的共享存储位置.也就是JournalNode列表
                 该url的配置格式:qjournal://host1:port1;host2:port2;host3:port3/journalId
        journalId推荐使用nameservice,默认端口号是:8485 -->
    <property>
        <name>dfs.namenode.shared.edits.dir</name>
        <value>qjournal://bigdata1:8485;bigdata2:8485;bigdata3:8485;/ns</value>
    </property>

    <!-- 指定JournalNode在本地磁盘存放数据的位置 -->
    <property>
        <name>dfs.journalnode.edits.dir</name>
        <value>/opt/datastore/hadoop/journaldata</value>
    </property>

    <!-- 开启NameNode失败自动切换 -->
    <property>
        <name>dfs.ha.automatic-failover.enabled</name>
        <value>true</value>
    </property>

    <!-- 配置失败自动切换实现方式 -->
    <property>
        <name>dfs.client.failover.proxy.provider.ns</name>
        <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
    </property>

    <!-- 配置隔离机制方法,多个机制用换行分割,即每个机制暂用一行 -->
    <property>
        <name>dfs.ha.fencing.methods</name>
        <value>
            sshfence
            shell(/bin/true)
        </value>
    </property>

    <!-- 使用sshfence隔离机制时需要ssh免登陆 -->
    <property>
        <name>dfs.ha.fencing.ssh.private-key-files</name>
        <value>/root/.ssh/id_rsa</value>
    </property>

    <!-- 配置sshfence隔离机制超时时间 -->
    <property>
        <name>dfs.ha.fencing.ssh.connect-timeout</name>
        <value>30000</value>
    </property>

    <property>
        <name>ha.failover-controller.cli-check.rpc-timeout.ms</name>
        <value>60000</value>
    </property>
</configuration>

vi mapred-site.xml

<configuration>
    <!-- 指定mr框架为yarn方式 -->
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>

    <!-- 指定mapreduce jobhistory地址 -->
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>bigdata1:10020</value>
    </property>

    <!-- 任务历史服务器的web地址 -->
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>bigdata1:19888</value>
    </property>
</configuration>

vi yarn-site.xml

<configuration>
    <!-- 开启RM高可用 -->
    <property>
        <name>yarn.resourcemanager.ha.enabled</name>
        <value>true</value>
    </property>

    <!-- 指定RM的cluster id -->
    <property>
        <name>yarn.resourcemanager.cluster-id</name>
        <value>yrc</value>
    </property>

    <!-- 指定RM的名字 -->
    <property>
        <name>yarn.resourcemanager.ha.rm-ids</name>
        <value>rm1,rm2</value>
    </property>

    <!-- 分别指定RM的地址 -->
    <property>
        <name>yarn.resourcemanager.hostname.rm1</name>
        <value>bigdata2</value>
    </property>

    <property>
        <name>yarn.resourcemanager.hostname.rm2</name>
        <value>bigdata3</value>
    </property>

    <!-- 指定zk集群地址 -->
    <property>
        <name>yarn.resourcemanager.zk-address</name>
        <value>bigdata1:2181,bigdata2:2181,bigdata3:2181</value>
    </property>

    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>

    <property>
        <name>yarn.log-aggregation-enable</name>
        <value>true</value>
    </property>

    <property>
        <name>yarn.log-aggregation.retain-seconds</name>
        <value>86400</value>
    </property>

    <!-- 启用自动恢复 -->
    <property>
        <name>yarn.resourcemanager.recovery.enabled</name>
        <value>true</value>
    </property>

    <!-- 制定resourcemanager的状态信息存储在zookeeper集群上 -->
    <property>
        <name>yarn.resourcemanager.store.class</name>
        <value>org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore</value>
    </property>

    <property>
        <name>yarn.log.server.url</name>
        <value>http://bigdata1:19888/jobhistory/logs</value>
    </property>

    <!-- 主要是给节点分配的内存少 yarn kill了spark application -->
    <property>
        <name>yarn.nodemanager.pmem-check-enabled</name>
        <value>false</value>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
        <description>Whether virtual memory limits will be enforced for containers</description>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-pmem-ratio</name>
        <value>4</value>
        <description>Ratio between virtual memory to physical memory when setting memory limits for containers</description>
    </property>
</configuration>

vi slaves
bigdata1
bigdata2
bigdata3


zkServer.sh start

#journalnode节点上启动journalnode进程
hadoop-daemon.sh start journalnode
#在第一个namenode节点上格式化文件系统
hadoop namenode -format
#要把在bigdata1节点上生成的元数据 给复制到 另一个namenode(bigdata2)节点上
scp -r /opt/datastore/hadoop/dfs bigdata2:/opt/datastore/hadoop/
#格式化ZKFC(任选一个namenode节点格式化)
hdfs zkfc -formatZK

#启动hdfs
start-dfs.sh
#启动yarn
start-yarn.sh
# 需要在另外一个resourcemanager节点手动启动resourcemanager
yarn-daemon.sh start resourcemanager

#启动 mapreduce 任务历史服务器
mr-jobhistory-daemon.sh start historyserver

hdfs dfsadmin -report

hdfs haadmin -getServiceState nn1
hdfs haadmin -getServiceState nn2
yarn rmadmin -getServiceState rm1
yarn rmadmin -getServiceState rm2


vi spark-env.sh
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-0.el7_6.x86_64
export HADOOP_HOME=/opt/software/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoo

vi spark-defaults.conf
spark.yarn.jars=hdfs://bigdata1:9000/tmp/spark/lib_jars/*

vi slaves
bigdata1
bigdata2
bigdata3



  cp /opt/software/spark/yarn/spark-2.4.3-yarn-shuffle.jar /opt/software/hadoop/share/hadoop/yarn/

hadoop fs -mkdir -p hdfs://bigdata1:9000/tmp/spark/lib_jars/
hadoop fs  -put /opt/software/spark/jars/*  hdfs://bigdata1:9000/tmp/spark/lib_jars/

cd /opt/software/spark/conf
  vi spark-defaults.conf

  spark.yarn.jars hdfs://bigdata1:9000/tmp/spark/lib_jars/*.jar
spark.shuffle.service.enabled true
spark.shuffle.service.port 7337

spark.sql.hive.thriftServer.singleSession true

vi
export SPARK_DIST_CLASSPATH=$(/opt/software/hadoop/bin/hadoop classpath)
export HADOOP_CONF_DIR=/opt/software/hadoop/etc/hadoop
export YARN_CONF_DIR=/opt/software/hadoop/etc/hadoop
# 这里是Spark的配置文件所在的目录，在本例中为：$spark_home/conf
export SPARK_CONF_DIR=/opt/software/spark/conf

# 为Spark Thrift Server分配的内存大小
export SPARK_DAEMON_MEMORY=1024m

    echo "Install success."

    return 0
}

function uninstall()
{
    result=`rpm -qa | grep java-1.`

    for i in ${result[@]}
    do
        echo "Remove package "$i
        rpm -e --nodeps $i
    done

    echo "Uninstall success."
}

if [ ! `id -u` = "0" ]; then
    echo "Please run as root user"
    exit 1
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

