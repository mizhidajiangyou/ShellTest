#!/bin/bash


source /etc/profile
cron_file="/etc/cron.d/KINGBASECRON"


command_options="-q -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p 22"
default_pass="MTIzNDU2NzhhYgo="


function err_log()
{
    local exit_flag=$?
    local message="$1"

    if [ ${exit_flag} -ne 0 ]
    then
        echo "${message} fail"
    else
        echo "${message} success"
    fi
}

function pre_exe(){
    DB_PATH=/home/kingbase/install/kingbase
    etc_PATH=${DB_PATH}/etc
    if [ "$DATA_DIR"x == ""x ]
    then
        DATA_DIR=/home/kingbase/userdata/data
    fi
    persist_etc_PATH=${DATA_DIR}/../etc
    LOG_FILE=${DATA_DIR}/logfile
    [ "$PASSWORD"x == ""x ] && PASSWORD=`echo "${default_pass}" | base64 -d`
    [ "$DB_USER"x == ""x ] && DB_USER=system
    [ "$DB_MODE"x == ""x ] && DB_MODE=oracle
    kingbase_user_exist=`cat /etc/bashrc |grep KINGBASE_USER|wc -l`
    [ $kingbase_user_exist -eq 0 ] && sudo echo "export KINGBASE_USER=${DB_USER}" | sudo tee -a /etc/bashrc
    sudo mkdir -p `dirname $DATA_DIR`
    sudo chown -R kingbase:kingbase /home/kingbase/
    sudo chmod -R 700 $DATA_DIR
    test ! -d ${persist_etc_PATH} && mkdir -p ${persist_etc_PATH}
    test ! -d ${etc_PATH} && ln -s ${persist_etc_PATH} ${etc_PATH}
}
function load_env(){
   [ "$DB_PASSWORD"x != ""x ] && PASSWORD=$DB_PASSWORD
   [ "$USER_DATA"x != ""x ] && DATA_DIR=/home/kingbase/$USER_DATA
   [ "$NEED_START"x == ""x ] && NEED_START=yes
   [ "$ENABLE_CI"x == ""x ] && ENABLE_CI=yes
   [ "$ENCODING"x == ""x ] && ENCODING=UTF-8
}
function check_and_run(){
   local DATA_DIR=$1
   pre_exe
   ${DB_PATH}/bin/sys_ctl -D ${DATA_DIR} status  2>/dev/null
   if [ $? -ne 0 ];then
       echo "[`date`]db is not running, ${DB_PATH}/bin/sys_ctl -D ${DATA_DIR} -l ${DATA_DIR}/logfile start"
       ${DB_PATH}/bin/sys_ctl -D ${DATA_DIR} -l ${LOG_FILE} start
       [ $? -eq 0 ] &&  echo "[`date`]db started" && return 0
       echo "[`date`]db start fail"
       return 0
   fi
}

function start_cron()
{
    local i=0
    local cron_command="* * * * * kingbase /home/kingbase/docker-entrypoint.sh check_and_run ${DATA_DIR} >> /home/kingbase/cronlog"
    #  root用户添加CRON任务
    local cronexist=`sudo cat $cron_file 2>/dev/null| grep -wFn "${cron_command}" |wc -l`
    if [ "$cronexist"x != ""x ] && [ $cronexist -eq 1 ]
    then
        local realist=`sudo cat $cron_file | grep -wFn "${cron_command}"`
        local linenum=`echo "${realist}" |awk -F':' '{print $1}'`
        sudo sed ${linenum}s/#*// $cron_file > ${persist_etc_PATH}/KINGBASECRON
        sudo cat ${persist_etc_PATH}/KINGBASECRON | sudo tee -a  $cron_file
    elif [ "$cronexist"x != ""x ] && [ $cronexist -eq 0 ]
    then
        sudo chmod 777 $cron_file
        sudo echo -e "${cron_command}\n" |sudo tee -a  $cron_file
        sudo chmod 644 $cron_file
    else
        return 1
    fi
    return 0
}


function db_init(){
    if [ "$ENABLE_CI"x == "yes"x ]
    then
        ${DB_PATH}/bin/initdb -U$DB_USER -x ${PASSWORD} -D ${DATA_DIR} -m ${DB_MODE} -E ${ENCODING} --enable-ci
    else
        ${DB_PATH}/bin/initdb -U$DB_USER -x ${PASSWORD} -D ${DATA_DIR} -m ${DB_MODE} -E ${ENCODING}
    fi

    sed -i 's/local   all             all                                     scram-sha-256/local   all             all                                     trust/g' ${DATA_DIR}/kingbase.conf
    sed -i 's/local   replication     all                                     scram-sha-256/local   replication     all                                     trust/g' ${DATA_DIR}/kingbase.conf
    sed -i 's/^#\(\s*archive_mode\s*=\s*\)off/\1on/'  ${DATA_DIR}/kingbase.conf
    sed -i "s|^#\(\s*archive_command\s*=\s*\)''|\1'/bin/true'|"  ${DATA_DIR}/kingbase.conf
    cp -rf ${etc_PATH}/license.dat ${DB_PATH}/bin/license.dat
    # mv ${DB_PATH}/bin/license.dat ${etc_PATH}/license.dat
    # ln -s ${etc_PATH}/license.dat ${DB_PATH}/bin/license.dat

}

function main(){
    load_env
    pre_exe
    if [ "$(ls -A ${DATA_DIR})" ];then
       echo "[`date`]data directory:${DATA_DIR} is not empty,don't need to initdb"
    else
       db_init
    fi

    if [ "$NEED_START"x == "yes"x ]
    then
        ${DB_PATH}/bin/sys_ctl -D ${DATA_DIR} -l ${LOG_FILE} start
        sudo chown -R root:root /etc/cron.d/
        sudo chmod -R 644 /etc/cron.d/
        test ! -f $cron_file &&  sudo touch $cron_file && sudo chmod 644 $cron_file
        start_cron
    elif [ "$NEED_START"x == "no"x ]
    then
        echo "[`date`]NEED_START be set as ${NEED_START},not yes, do not need start db"
        touch  ${LOG_FILE}
    fi

    if test -f ${etc_PATH}/logrotate_kingbase
    then
       echo "[`date`]cp logrotate_kingbase from  ${etc_PATH}/logrotate_kingbase  to /etc/logrotate.d/kingbase"
       sudo cp ${etc_PATH}/logrotate_kingbase  /etc/logrotate.d/kingbase
       err_log "cp ${etc_PATH}/logrotate_kingbase  /etc/logrotate.d/kingbase"
       sudo chmod 644 /etc/logrotate.d/kingbase
       sudo chown root:root /etc/logrotate.d/kingbase
    fi

    if test -f  ${etc_PATH}/KINGBASECRON
    then
       echo "[`date`]cp KINGBASECRON from  ${etc_PATH}/KINGBASECRON  to /etc/cron.d/KINGBASECRON"
       sudo cp ${etc_PATH}/KINGBASECRON  /etc/cron.d/KINGBASECRON
       err_log "sudo cp ${etc_PATH}/KINGBASECRON  /etc/cron.d/KINGBASECRON"
       sudo chmod 644 /etc/cron.d/KINGBASECRON
       sudo chown root:root /etc/cron.d/KINGBASECRON
    fi

    if test -f ${etc_PATH}/${USER}
    then
       crontab ${etc_PATH}/${USER}
    fi

    if test -f ${etc_PATH}/.encpwd
    then
       echo "[`date`]cp .encpwd from  ${etc_PATH}/.encpwd to ~/.encpwd"
       cp ${etc_PATH}/.encpwd  ~/.encpwd
       err_log "cp ${etc_PATH}/.encpwd  ~/.encpwd"
       sudo chmod 600 ~/.encpwd
       sudo chown ${USER}:${USER} ~/.encpwd
    fi
    while true;do sleep 1000;done
}
case $1 in
    "check_and_run")
        shift
        check_and_run $1
        exit 0
        ;;
    *)
        main
esac