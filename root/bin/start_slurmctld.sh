#!/bin/bash


if [ ! -d /chome/cluser ];then
   userdel cluser
   useradd -u 2000 -d /chome/cluser -m cluser
   echo "cluser:cluser"|chpasswd
   mv /root/ssh /chome/cluser/.ssh
   chown -R cluser:cluser /chome/cluser/.ssh
   chmod 600 /chome/cluser/.ssh/authorized_keys
   chmod 600 /chome/cluser/.ssh/id_rsa
   chmod 644 /chome/cluser/.ssh/id_rsa.pub
fi

sleep 5

/usr/local/sbin/slurmctld -D -v -c
