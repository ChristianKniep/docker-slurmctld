###### Slurmctld images
# A docker image that provides a slurmctld
FROM qnib/slurm
MAINTAINER "Christian Kniep <christian@qnib.org>"

ADD etc/supervisord.d/slurmctld.ini /etc/supervisord.d/
ADD usr/local/bin/sctld_epilog.sh /usr/local/bin/
ADD usr/local/bin/sctld_prolog.sh /usr/local/bin/

ADD root/cluser_ssh.tar /root/
ADD root/bin/start_slurmctld.sh /root/bin/
ADD etc/supervisord.d/confd_update_slurm.ini /etc/supervisord.d/confd_update_slurm.ini

ADD usr/local/bin/gemm.sh /usr/local/bin/gemm.sh

CMD /bin/supervisord -c /etc/supervisord.conf
