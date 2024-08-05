#!/bin/bash
ADMIN_PWD=${SYSDBA_PWD}
CONN_PWD=\"${ADMIN_PWD}\"
export LANG=en_US.UTF-8
function wait_dm_running() {
  for i in `seq 1  10`
  do
    if [ ! -f "/opt/dmdbms/conf/dm.ini" ]; then
       pid=`ps -eo pid,args | grep -F "./dmserver /opt/dmdbms/data/DAMENG/dm.ini" | grep -v "grep" | tail -1 | awk '{print $1}'`
    else
       pid=`ps -eo pid,args | grep -F "./dmserver /opt/dmdbms/conf/dm.ini" | grep -v "grep" | tail -1 | awk '{print $1}'`
    fi
    if [ "$pid" != "" ]; then
      echo "Dmserver is running."
      break
    else
      echo "Dmserver is not running yet..."
      sleep 10
    fi
  done
}
function wait_dm_ready() {
  for i in `seq 1  10`
  do
    echo `./disql /nolog <<EOF
CONN SYSDBA/${CONN_PWD}@localhost
exit
EOF` | grep  "connection failure" > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
      echo "DM Database is not OK, please wait..."
      sleep 10
    else
      echo "DM Database is OK"
      break
    fi
  done
}
if [ ! -d "/opt/dmdbms/data/DAMENG" ]; then
   cd /opt/dmdbms/bin
   ./dminit PATH=/opt/dmdbms/data PAGE_SIZE=${PAGE_SIZE} CASE_SENSITIVE=${CASE_SENSITIVE} UNICODE_FLAG=${UNICODE_FLAG} LENGTH_IN_CHAR=${LENGTH_IN_CHAR} SYSDBA_PWD=${ADMIN_PWD}
   echo "Init DM success!"
fi
cd /opt/dmdbms/bin
echo "Start DmAPService..."
./DmAPService start
if [ ! -f "/opt/dmdbms/conf/dm.ini" ]; then
   echo "/opt/dmdbms/conf/dm.ini does not exist, use default dm.ini"
   ./dmserver /opt/dmdbms/data/DAMENG/dm.ini -noconsole > /opt/dmdbms/log/DmServiceDMSERVER.log 2>&1 &
else
   ./dmserver /opt/dmdbms/conf/dm.ini -noconsole > /opt/dmdbms/log/DmServiceDMSERVER.log 2>&1 &
fi
echo "Start DMSERVER success!"
wait_dm_running
wait_dm_ready
if [ ! -f "/opt/dmdbms/log/dm_DMSERVER.log" ]; then
   current_year_month=`date +%Y%m`
   DM_LOG=dm_DMSERVER_${current_year_month}.log
   ln -s /opt/dmdbms/log/${DM_LOG} /opt/dmdbms/log/dm_DMSERVER.log
   echo "Finished soft link DM current ${DM_LOG} to dm_DMSERVER.log"
fi
echo "5 0 1 * * root /opt/switchDmLog.sh" >> /etc/crontab
#systemctl restart crond.service
/etc/init.d/cron start
#echo "Start Cron Service"
tail -F /opt/dmdbms/log/dm_DMSERVER.log
tail -f /dev/null