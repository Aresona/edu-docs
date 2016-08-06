#!/bin/bash

# mkdir -p /deploy/code/web-demo -p
# mkdir -p /deploy/config/web-demo/base
# mkdir -p /deploy/config/web-demo/other
# mkdir -p /deploy/tar
# mkdir -p /deploy/tmp
# mkdir -p /opt/webroot
# mkdir /webroot
# chown -R www:www /deploy
# chown -R www:www /opt/webroot
# chown -R www:www /webroot


# Node List
PRE_LIST="192.168.56.11"
GROUP1_LIST="192.168.56.12"
ROLLBACK_LIST="192.168.56.11 192.168.56.12"
# Log Date/Time Variables
LOG_DATE='date "+%Y-%m-%d"'
LOG_TIME='date "+%H-%M-%S"'

CDATE=$(date "+%Y-%m-%d")
CTIME=$(date "+%H-%M-%S")
# SHELL ENV
SHELL_NAME="deploy.sh"
SHELL_DIR="/home/www/"
SHELL_LOG="${SHELL_DIR}/${SHELL_NAME}.log"

# Code Env
PRO_NAME="web-demo"
CODE_DIR="/deploy/code/web-demo"
CONFIG_DIR="/deploy/config/web-demo"
TMP_DIR="/deploy/tmp"
TAR_DIR="/deploy/tar"
LOCK_FILE="/tmp/deploy.lock"

usage(){
	echo $"Usage: $0 {deploy | rollback [ list | version ]"
}

writelog(){
	LOGINFO=$1
	echo "${CDATE} ${CTIME}: ${SHELL_NAME}: ${LOGINFO}" >> ${SHELL_LOG}
}

shell_lock(){
	touch ${LOCK_FILE}
}

shell_unlock(){
	rm -f ${LOCK_FILE}
}

code_get(){
	writelog "code_get"
	cd $CODE_DIR && git pull
	cp -r ${CODE_DIR} ${TMP_DIR}/
	API_VERL=$(git show |grep commit|cut -d ' ' -f2)
	API_VER=$(echo ${API_VERL:0:6})
}


code_build(){
	echo code_build
}

code_config(){
	writelog "code_config"
	/bin/cp -r ${CONFIG_DIR}/base/*  ${TMP_DIR}/${PRO_NAME}
	PKG_NAME="${PRO_NAME}"_"${API_VER}"_"${CDATE}_${CTIME}"
	cd ${TMP_DIR} && mv ${PRO_NAME} ${PKG_NAME}

}

code_tar(){
	writelog "code_tar"
	cd ${TMP_DIR} && tar zcf ${PKG_NAME}.tar.gz ${PKG_NAME}
	writelog "${PKG_NAME}.tar.gz"
	
}

code_scp(){
	for node in ${PRE_LIST};do
		scp ${TMP_DIR}/${PKG_NAME}.tar.gz $node:/opt/webroot
	done
	for node in ${GROUP1_LIST};do
		scp ${TMP_DIR}/${PKG_NAME}.tar.gz $node:/opt/webroot
	done
}

cluster_node_remove(){
	writelog "cluster_node_remove"

}

# 当做预生产节点
pre_deploy(){
	writelog "remove from cluster"
		ssh $PRE_LIST "cd /opt/webroot && tar zxf ${PKG_NAME}.tar.gz"
		ssh $PRE_LIST "rm -f /webroot/web-demo && ln -s /opt/webroot/${PKG_NAME} /webroot/web-demo"
}

url_test(){
	URL=$1
	curl -Is $URL | grep 200
	if [ $? -ne 0 ];then
		shell_unlock
		writelog "test error" && exit
	fi
}

pre_test(){
	url_test "http://$PRE_LIST/index.html"
	echo "add to cluster"
}

group1_deploy(){
	writelog "remove from cluster"
	for node in ${GROUP1_LIST};do
		ssh $node "cd /opt/webroot && tar zxf ${PKG_NAME}.tar.gz"
		ssh $node "rm -f /webroot/web-demo && ln -s /opt/webroot/${PKG_NAME} /webroot/web-demo"
	done
	scp ${CONFIG_DIR}/other/192.168.56.12.crontab.xml www@192.168.56.12:/opt/webroot/${PKG_NAME}/crontab.xml
}

group1_test(){
	url_test "http://192.168.56.11/index.html"
	echo "add to cluster"
}

rollback_fun(){
        for node in ${ROLLBACK_LIST};do
                ssh $node "rm -f /webroot/web-demo && ln -s /opt/webroot/$1 /webroot/web-demo"
	done
}

rollback(){
	[ -z $1 ] && echo "hehe" && shell_unlock && exit
	case $1 in
	    list)
		ls -lrt /opt/webroot/*.tar.gz
	    ;;
	    *)
	   	rollback_fun $1
	esac
}


main(){
  if [ -f $LOCK_FILE ];then
	echo "Deploy is running" && exit
  fi
    D_METHOD=$1
    ROLLBACK_VER=$2
    case $D_METHOD in
      deploy)
	shell_lock;
 	code_get;
	code_build;
	code_config;
	code_tar;
	code_scp;
	pre_deploy;
#	pre_test;
	group1_deploy;
	group1_test;
	shell_unlock;
	;;
      rollback)
	shell_lock;
	rollback $ROLLBACK_VER
	shell_unlock;
	;;
      *)
	usage;
      esac
}
main $1 $2
