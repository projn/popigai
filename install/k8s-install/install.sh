#!/bin/bash

CURRENT_WORK_DIR=$(cd `dirname $0`; pwd)
source ${CURRENT_WORK_DIR}/config.properties

function usage()
{
    echo "Usage: install.sh [--help]"
    echo ""
    echo "install kubernetes."
    echo ""
    echo "  --help                  : help."
    echo ""
    echo "  --pre-master        : install master."
    echo "  --install-master        : install master."
    echo "  --install-master        : install master."
    echo "  --install-node          : install node."
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

function init_host_step1()
{
    # 关闭Selinux/firewalld
    systemctl stop firewalld
    systemctl disable firewalld
    setenforce 0
    sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

    # 关闭交换分区
    swapoff -a
    yes | cp /etc/fstab /etc/fstab_bak
    cat /etc/fstab_bak |grep -v swap > /etc/fstab

    # 同步时间
    yum install -y ntpdate
    ntpdate -u ntp.api.bz

    # 升级内核
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm ;yum --enablerepo=elrepo-kernel install kernel-ml-devel kernel-ml -y

    # 检查默认内核版本是否大于4.14，否则请调整默认启动参数
    #grub2-editenv list

    # 重启以更换内核
    reboot
}

function init_host_step2()
{
    # 确认内核版本后 开启IPVS
    uname -a

    echo ""'#!/bin/bash
ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_fo ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack"
for kernel_module in \${ipvs_modules}; do
 /sbin/modinfo -F filename \${kernel_module} > /dev/null 2>&1
 if [ $? -eq 0 ]; then
 /sbin/modprobe \${kernel_module}
 fi
done
    '"" > /etc/sysconfig/modules/ipvs.modules

    chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep ip_vs

    # 设置网桥包经IPTables core文件生成路径
    echo """vm.swappiness = 0
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
    """ > /etc/sysctl.conf
    sysctl -p

    # Kubernetes要求集群中所有机器具有不同的Mac地址 产品uuid Hostname
    #hostnamectl set-hostname ${HOST_NAME}

    yum install -y socat keepalived ipvsadm

    # 配置免密码登陆
    # master-1 生成ssh密钥对

    #ssh-keygen
    # 三次回车后 密钥生成完成
    #cat ~/.ssh/id_rsa.pub
    # 复制该公钥 并分别登陆到master-1 master-2 master-3的root用户，将它令起一行粘贴到 ~/.ssh/authorized_keys文件中 包括master-1自己
}

function pre_install_k8s()
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

    cd /etc/yum.repos.d/
    wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

    echo "[kubernetes]" >> /etc/yum.repos.d/kubernetes.repo
    echo "name=Kubernetes Repo" >> /etc/yum.repos.d/kubernetes.repo
    echo "baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/" >> /etc/yum.repos.d/kubernetes.repo
    echo "gpgcheck=1" >> /etc/yum.repos.d/kubernetes.repo
    echo "gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg" >> /etc/yum.repos.d/kubernetes.repo
    echo "enables=1" >> /etc/yum.repos.d/kubernetes.repo

    yum repolist
    yum install -y docker-ce kubelet kubeadm kubectl
    mkdir -p /etc/docker
    echo "{"  >> /etc/docker/daemon.json
    echo '"registry-mirrors": ["https://5q5g7ksn.mirror.aliyuncs.com"]'  >> /etc/docker/daemon.json
    echo "}"  >> /etc/docker/daemon.json

    systemctl enable kubelet
    systemctl enable docker
    systemctl stop firewalld
    systemctl disable firewalld
    systemctl daemon-reload
    systemctl restart docker
    systemctl restart kubelet

    docker pull mirrorgooglecontainers/kube-apiserver-amd64:v1.13.3
    docker pull mirrorgooglecontainers/kube-controller-manager-amd64:v1.13.3
    docker pull mirrorgooglecontainers/kube-scheduler-amd64:v1.13.3
    docker pull mirrorgooglecontainers/kube-proxy-amd64:v1.13.3
    docker pull mirrorgooglecontainers/pause:3.1
    docker pull mirrorgooglecontainers/etcd-amd64:3.2.24
    docker pull coredns/coredns:1.2.6

    docker tag mirrorgooglecontainers/kube-proxy-amd64:v1.13.3 k8s.gcr.io/kube-proxy:v1.13.3
    docker tag mirrorgooglecontainers/kube-apiserver-amd64:v1.13.3 k8s.gcr.io/kube-apiserver:v1.13.3
    docker tag mirrorgooglecontainers/kube-controller-manager-amd64:v1.13.3 k8s.gcr.io/kube-controller-manager:v1.13.3
    docker tag mirrorgooglecontainers/kube-scheduler-amd64:v1.13.3 k8s.gcr.io/kube-scheduler:v1.13.3
    docker tag mirrorgooglecontainers/pause:3.1 k8s.gcr.io/pause:3.1
    docker tag mirrorgooglecontainers/etcd-amd64:3.2.24 k8s.gcr.io/etcd:3.2.24
    docker tag coredns/coredns:1.2.6 k8s.gcr.io/coredns:1.2.6

    return 0
}

function install_single_master()
{
    kubeadm init --kubernetes-version=v1.13.3 --pod-network-cidr=${K8S_PODS_IP_SEGMENT} --service-cidr=${K8S_SERVICE_IP_SEGMENT}

    su ${SOFTWARE_USER_NAME} -c 'mkdir -p $HOME/.kube'
    cp -i /etc/kubernetes/admin.conf /home/${SOFTWARE_USER_NAME}/.kube/config
    chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} /home/${SOFTWARE_USER_NAME}/.kube/config

    hostnamectl set-hostname master.${HOST_NAME_DOMAIN}

    su ${SOFTWARE_USER_NAME} -c 'kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml'
}

function config_keepalived_master()
{

    rm -rf /etc/keepalived/keepalived.conf
    echo """
global_defs {
   notification_email {
     root@localhost
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server 127.0.0.1
   smtp_connect_timeout 30
   router_id master1.k8s.projn.com #备份调度器的主机名
}

vrrp_instance VI_1 {
    state MASTER #主调度器的初始角色 MASTER BACKUP
    interface ens33
    virtual_router_id 51
    priority 100 #主调度器的选举优先级
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        """${K8S_KEEPALIVED_VIP}""" #虚拟IP
    }
}
""" >> /etc/keepalived/keepalived.conf

    systemctl enable keepalived
    systemctl restart keepalived

    return 0;

}

function config_keepalived_backup()
{

    rm -rf /etc/keepalived/keepalived.conf
    echo """
global_defs {
   notification_email {
     root@localhost
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server 127.0.0.1
   smtp_connect_timeout 30
   router_id master"""${1}""".k8s.projn.com #备份调度器的主机名
}

vrrp_instance VI_1 {
    state BACKUP #主调度器的初始角色 MASTER BACKUP
    interface ens33
    virtual_router_id 51
    priority 100 #主调度器的选举优先级
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        """${K8S_KEEPALIVED_VIP}""" #虚拟IP
    }
}
""" >> /etc/keepalived/keepalived.conf

    systemctl enable keepalived
    systemctl restart keepalived

    return 0;
}

function install_cluster_master()
{
    pre_install_k8s
    if [ $? != 0 ]; then
        echo "pre install k8s failed,check it please."
        return 1;
    fi

    hostnamectl set-hostname master${1}.${HOST_NAME_DOMAIN}
    if [ $1 == 1 ]; then
        config_keepalived_master
        if [ $? != 0 ]; then
            echo "config keepalived master failed,check it please."
            return 1;
        fi

        echo ""'
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: 1.13.3
apiServer:
  certSANs:
  - "'""${K8S_KEEPALIVED_VIP}""'"
controlPlaneEndpoint: "'""${K8S_KEEPALIVED_VIP}""'"
'"" >> kubeadm-config.yaml

        kubeadm init --config=kubeadm-config.yaml

        su ${SOFTWARE_USER_NAME} -c 'mkdir -p $HOME/.kube'
        cp -i /etc/kubernetes/admin.conf /home/${SOFTWARE_USER_NAME}/.kube/config
        chown ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} /home/${SOFTWARE_USER_NAME}/.kube/config

        count=1
        for host in ${K8S_MASTER_IP_LIST[@]}; do
            if [ ${count} == 1 ]; then
                echo "master${count}.${HOST_NAME_DOMAIN} ${host}" >> /etc/hosts
            else
                echo "master${count}.${HOST_NAME_DOMAIN} ${host}" >> /etc/hosts

                scp /etc/kubernetes/pki/ca.crt root@$host:
                scp /etc/kubernetes/pki/ca.key root@$host:
                scp /etc/kubernetes/pki/sa.key root@$host:
                scp /etc/kubernetes/pki/sa.pub root@$host:
                scp /etc/kubernetes/pki/front-proxy-ca.crt root@$host:
                scp /etc/kubernetes/pki/front-proxy-ca.key root@$host:
                scp /etc/kubernetes/pki/etcd/ca.crt root@$host:etcd-ca.crt
                scp /etc/kubernetes/pki/etcd/ca.key root@$host:etcd-ca.key
                scp /etc/kubernetes/admin.conf root@$host:
            fi
            ((count++))
        done

        su ${SOFTWARE_USER_NAME} -c 'kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d "\n")"'
        #kubectl get pod -n kube-system -w

    else
        config_keepalived_backup $1
        if [ $? != 0 ]; then
            echo "config keepalived master failed,check it please."
            return 1;
        fi

        mkdir -p /etc/kubernetes/pki/etcd
        mv /root/ca.crt /etc/kubernetes/pki/
        mv /root/ca.key /etc/kubernetes/pki/
        mv /root/sa.pub /etc/kubernetes/pki/
        mv /root/sa.key /etc/kubernetes/pki/
        mv /root/front-proxy-ca.crt /etc/kubernetes/pki/
        mv /root/front-proxy-ca.key /etc/kubernetes/pki/
        mv /root/etcd-ca.crt /etc/kubernetes/pki/etcd/ca.crt
        mv /root/etcd-ca.key /etc/kubernetes/pki/etcd/ca.key
        mv /root/admin.conf /etc/kubernetes/admin.conf

        ${K8S_MASTER_JOIN_CMD} --experimental-control-plane
    fi

    return 0;
}

function install_node()
{
    pre_install_k8s
    if [ $? != 0 ]; then
        echo "pre install k8s failed,check it please."
        return 1;
    fi
    hostnamectl set-hostname node${1}.${HOST_NAME_DOMAIN}
    ${K8S_MASTER_JOIN_CMD}

    return 0
}

function install_dashboard()
{
    # https://github.com/kubernetes/dashboard
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml

    echo """
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system""" >> dashboard-adminuser.yaml

    kubectl apply -f dashboard-adminuser.yaml

    echo """apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system""" >> dashboard-cluster-user.yaml

  kubectl apply -f dashboard-cluster-user.yaml

  kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

  docker pull mirrorgooglecontainers/kubernetes-dashboard-amd64:v1.10.1

  docker tag mirrorgooglecontainers/kubernetes-dashboard-amd64:v1.10.1 k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1

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
step=$2

if [ "${opt}" == "--init-host" ]; then
    if [ "${step}" == "1" ]; then
        init_host_step1
    else
        init_host_step2
    fi
elif [ "${opt}" == "--install-single-master" ]; then
    install_single_master
elif [ "${opt}" == "--install-cluster-master" ]; then
    install_cluster_master ${step}
elif [ "${opt}" == "--install-node" ]; then
    install_node ${step}
elif [ "${opt}" == "--help" ]; then
    usage
else
    echo "Unknown argument"
fi