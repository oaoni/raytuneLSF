from collections import Counter
import socket
import time
import ray

import argparse

parser = argparse.ArgumentParser(description='Set parameters')
parser.add_argument("--port", type=str, help="Port number used by ray clusters",default='1297')
parser.add_argument("--hostip", type=str, help="Host IP in ray cluster",default='127.0.0.1')
parser.add_argument("--rpass", type=str, help="Redis password",default='9673532156')
parser.add_argument("--localdir", type=str, help="Path to run directory",default='run_raytune.py')
parser.add_argument("--modelname", type=str, help="name of model",default='None')
parser.add_argument("--datapath", type=str, help="Path to data file",default='None')
parser.add_argument("--cpus_per_trial", type=str, help="Number of cpus to utilize per trial", default="1")
parser.add_argument("-L","--runlocal", action='store_true', help="Run ray locally",default=False)

args = parser.parse_args()

PORT = args.port
HOST_IP = args.hostip
RPASS = args.rpass
LOCAL_DIR = args.localdir
MODELNAME = args.modelname
DATAPATH = args.datapath
RUNLOCAL = args.runlocal
CPUS_PER_TRIAL = float(args.cpus_per_trial)

if __name__ == '__main__':

    if RUNLOCAL:
        ray.init(object_store_memory=10**9)
    else:
        ray.init(address=":".join([HOST_IP,PORT]),_redis_password=RPASS)

    print('''This cluster consists of
        {} nodes in total
        {} CPU resources in total
    '''.format(len(ray.nodes()), ray.cluster_resources()['CPU']))

    start = time.time()

    @ray.remote
    def f():
        time.sleep(0.001)
        # Return IP address.
        return socket.gethostbyname(socket.gethostname())

    object_ids = [f.remote() for _ in range(100000)]
    ip_addresses = ray.get(object_ids)

    end = time.time()

    print('Tasks executed')
    for ip_address, num_tasks in Counter(ip_addresses).items():
        print('    {} tasks on {}'.format(num_tasks, ip_address))

    print('Total elapsed time was: {} seconds'.format(end - start))
