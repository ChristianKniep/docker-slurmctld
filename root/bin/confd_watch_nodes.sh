#!/bin/bash

DAEMON=$(/bin/supervisorctl status|grep slurm|awk '{print $1}')

function fetch_value {
   KEY=$(echo "/${1}"|sed -e 's#//#/#g')
   VALUE=$(curl -s -4 -L http://etcd:4001/v2/keys${KEY}| python -mjson.tool|grep value|head -n1)
   RESULT=$(echo ${VALUE}|awk -F\: '{print $2}'|sed -s 's/"//g'|sed -e 's/ //g')
   if [ "X${RESULT}" == "X" ];then
      return 1
   fi
   echo ${RESULT}
}

function fetch_nodelist {
   INT_LIST=$(curl -s -4 -L http://etcd:4001/v2/keys/helix/| python -mjson.tool|egrep -o "compute[0-9]+"|egrep -o "[0-9]+"|sort -n|xargs)
   echo ${INT_LIST}
}

function create_rangeset {
   RSET=""
   CNT="-1"
   PREV_CNT="-1"
   if [ $(echo $*|wc -w) -eq 1 ];then
      echo $*
      return 0
   fi
   for INT in $*;do
      if [ ${CNT} -ne ${INT} ];then
         if [ ${CNT} -eq -1 ];then
             CNT=0
         fi
         if [ "X${RSET}" != "X" ];then 
             RSET="${RSET}-${PREV_CNT},"
         fi
         CNT=${INT}
         RSET="${RSET}${CNT}"
      fi
      PREV_CNT=${CNT}
      CNT=$(echo "${CNT} + 1"|bc)
   done
   RSET="${RSET}-${PREV_CNT}"
   echo "[${RSET}]"
}

function set_key {
   VAL=${2}
   KEY=$(echo "/${1}"|sed -e 's#//#/#g')
   curl -s -o /dev/null -4 -XPUT http://etcd:4001/v2/keys${KEY} -d value=${2}
   SET_VAL=$(fetch_value ${1})
   if [ "X${VAL}" == "X${SET_VAL}" ];then
       return 0
   else
       echo "ERROR >> key: ${1}"
       echo "[ ${VAL} != ${SET_VAL} ]"
       return 1
   fi
}

function update_nodename {
    RANGE_SET=$(create_rangeset $(fetch_nodelist))
    set_key /slurm/conf/nodename "compute${RANGE_SET}"
    if [ $? -eq 0 ];then
       echo "OK >> updated /slurm/conf/nodename := compute${RANGE_SET}"
       set_key /slurm/conf/last_update $(date +%s)
    else
       echo "ERROR >> Something went wrong during /slurm/conf/nodename := compute${RANGE_SET}"
       exit 1
    fi
    PREV_RANGE_SET=${RANGE_SET}
}

### MAIN
update_nodename
while [ true ];do
   /bin/timeout 1m /root/bin/watch_change.sh
   RANGE_SET=$(create_rangeset $(fetch_nodelist))
   if [ "X${PREV_RANGE_SET}" != "X${RANGE_SET}" ];then
      update_nodename
   fi 
   sleep 1
done
