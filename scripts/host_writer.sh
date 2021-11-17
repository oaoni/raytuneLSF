#!/usr/bin/bash

HOST_IP=`hostname -i`
echo $LSB_MCPU_HOSTS
echo $HOST_IP
eval "NODES=($LSB_MCPU_HOSTS)"
LEN_NODES=${#NODES[@]}
NUM_NODES=`expr $LEN_NODES / 2`
echo "The HOST node is ${NODES[0]}, and there are $NUM_NODES nodes in total"

for ((i=2;i< $LEN_NODES  ;i+=2));
do
  echo "    Worker node on: ${NODES[i]}"
  echo "    The worker node: ${NODES[i]}, can run ${NODES[i-1]} processes"
done

#What it actually needs to do, save a temp file,
echo "Saving host node metadata..."
printf "$LSB_MCPU_HOSTS\n$HOST_IP\n$PWD\n$LSB_JOBID" > hosts.tmp

screen -S writer -dm
