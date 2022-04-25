#!/usr/bin/bash

RESOURCES=$1
WALLTIME=$2
CWD=$3
PORT=$4
REDIS_PASSWORD=$5
NCPUS=$6
NGPUS=$7
HOSTWRITER=$8
NPROCESSES=$9
CONDAENV=${10}
RAYENV=${11}
DASHPORT=${12}
RAYAPP=${13}
MODELNAME=${14}
DATAPATH=${15}
CPUSPERTRIAL=${16}
APP_ARGS=${17}

echo "Submitting Job..."
bsub -o %J.o -e %J.e -n $NPROCESSES -R "$RESOURCES" -W $WALLTIME -cwd $CWD -I /usr/bin/bash $HOSTWRITER

# Load host node metadata
cd $CWD
echo $PWD
TEMPFILE=$(<"$CWD/hosts.tmp")

# Assign variables
HOSTS=`sed -n 1p <<< "$TEMPFILE"`
HOST_IP=`sed -n 2p <<< "$TEMPFILE"`
DIR=`sed -n 3p <<< "$TEMPFILE"`
JOBID=`sed -n 4p <<< "$TEMPFILE"`

eval "NODES=($HOSTS)"
LEN_NODES=${#NODES[@]}
NUM_NODES=`expr $LEN_NODES / 2`
echo "The HOST node is ${NODES[0]}, and there are $NUM_NODES nodes in total"

# Run Ray on nodes
echo "Starting head node on: ${NODES[0]}"
# Start Ray on head node
ssh -A -T $USER@${NODES[0]} << EOF
  echo "Activating Ray environment.."
  source $CONDAENV $RAYENV
  echo "Starting Ray head node"
  #Add command to specify juyter notebook port
  ray start --head --port=$PORT --redis-password=$REDIS_PASSWORD --dashboard-port=$DASHPORT --num-cpus=$NCPUS --num-gpus=$NGPUS --object-store-memory=$((16**9))
EOF

# Create string for ssh forwarding
echo "Access Ray Dashboard From the Following SSH Tunnel.."
echo "----------------------------------------------------"
echo "ssh -L $DASHPORT:127.0.0.1:$DASHPORT $USER@$HOSTNAME ssh -N -L $DASHPORT:127.0.0.1:$DASHPORT $USER@${NODES[0]}"
echo "----------------------------------------------------"

# Start Ray worker nodes
echo "Starting worker nodes"
for ((i=2;i< $LEN_NODES  ;i+=2));
do
  echo "    Worker node on: ${NODES[i]}"
  echo "    The worker node: ${NODES[i]}, can run ${NODES[i-1]} processes"

    ssh -A -T $USER@${NODES[i]} << EOF
    echo "Activating Ray environment.."
    source $CONDAENV $RAYENV
    echo "Starting Ray worker node"
    ray start --address=$HOST_IP:$PORT --redis-password=$REDIS_PASSWORD --num-cpus=$NCPUS --num-gpus=$NGPUS --object-store-memory=$((16**9))
EOF
done

######################
# Run ray application
######################
ssh -A $USER@${NODES[0]} << EOF
  echo "Activating Ray environment on head node.."
  source $CONDAENV $RAYENV

  cd $PWD
  python -c 'import os; print(os.getcwd())'
  eval python $RAYAPP --hostip $HOST_IP --port $PORT --rpass $REDIS_PASSWORD --localdir $CWD --modelname $MODELNAME --datapath $DATAPATH --cpus_per_trial $CPUSPERTRIAL $APP_ARGS
EOF
#########################
# End of ray tune script
#########################

# read -p "Press enter to continue, shutting down all ray clusters, and ending LSF job.."

# Shutdown all of the ray clusters
echo "SHUTTING DOWN ALL RAY CLUSTERS IN 10 SECONDS.."
sleep 10

for ((i=2;i< $LEN_NODES  ;i+=2));
do
  echo "    Shutting down worker node on: ${NODES[i]}"

    ssh -A -T $USER@${NODES[i]} << EOF
    echo "Activating Ray environment.."
    source $CONDAENV $RAYENV
    echo "Shutting down Ray worker node"
    sleep 1
    ray stop --log-style pretty
EOF
done

echo "Shutting down Ray head node"
ssh -A -T $USER@${NODES[0]} << EOF
  echo "Activating Ray environment.."
  source $CONDAENV $RAYENV
  echo "Shutting down Ray head node"
  sleep 1
  ray stop --log-style pretty

  screen -wipe
  screen -S writer -X quit

EOF

echo "    Closing Ray Dashboard ssh tunnel"
ps -ef | grep $USER | grep "ssh -N -L $DASHPORT:127.0.0.1:$DASHPORT $USER@${NODES[0]}" | tr -s ' ' | cut -d" " -f2 | xargs kill

# Kill bsub job
bkill $JOBID
