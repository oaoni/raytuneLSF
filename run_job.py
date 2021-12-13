from datetime import datetime
import subprocess
import os
from random import randrange

import argparse

parser = argparse.ArgumentParser(description='Run distributed ray applications with multinode LSF job submission')
parser.add_argument("-j", "--jobname", action='store', type=str, help='Name for job',default='RayJob')
parser.add_argument("-w", "--workdir", type=str, help="Working directory",default='../')
parser.add_argument("--jobrunner", type=str, help="Path to LSF job submitting and multinode ray runner",default='../raytuneLSF/scripts/job_runner.sh')
parser.add_argument("--hostwriter", type=str, help="Path to host node metadata writer",default='../raytuneLSF/scripts/host_writer.sh')
parser.add_argument("--nworkers", type=int, help="Number of worker nodes",default='2')
parser.add_argument("--cpusperworker", type=int, help="Number of processes per worker node",default='2')
parser.add_argument("--mempercpu", type=str, help="Memory per process in GBs", default='4')
parser.add_argument("--walltime", type=str, help="Walltime bsub -W option", default='0:30')
parser.add_argument("--port", type=str, help="Port number used by ray clusters")
parser.add_argument("--redispassword", type=str, help="Redis password of host node on ray cluster")
parser.add_argument("--ngpus", type=str, default='0', help="Number of GPUs")
parser.add_argument("--condaenv", type=str, default='~/anaconda3/bin/activate', help="Path to conda activate")
parser.add_argument("--rayenv", type=str, help="Name of conda Ray environment", default='rayenv')
parser.add_argument("--dashport", type=str, help="Ray dashboard port")
parser.add_argument("--rayapp", type=str, help="Path to distributed application", default='../raytuneLSF/ray_app.py')
parser.add_argument("--modelname", type=str, help="name of model", default='None')
parser.add_argument("--datapath", type=str, help="Path to data file", default='None')
parser.add_argument("--cpus_per_trial", type=str, help="Number of cpus to utilize per trial", default='1')
parser.add_argument("--app_args", type=str, help="Optional app arguments", default='None')
args = parser.parse_args()

def main():
    runID = datetime.now().strftime("%b%d_%H%M%S")
    jobName = args.jobname
    workDir = args.workdir
    runDir = os.path.join(workDir,"_".join([runID,jobName]))
    os.mkdir(runDir)

    jobRunner = args.jobrunner
    hostWriter = args.hostwriter
    memPerprocess = args.mempercpu
    nWorkers = args.nworkers
    cpusPerworker = args.cpusperworker
    nProcesses = nWorkers * cpusPerworker
    wallTime = args.walltime
    resources = "rusage[mem={}] span[ptile={}]".format(memPerprocess,cpusPerworker)
    redisPassword = str(args.redispassword if args.redispassword else randrange(10e12,10e13))
    nGpus = args.ngpus
    condaEnv = args.condaenv
    rayEnv = args.rayenv
    port = str(args.port if args.port else randrange(6000,7999))
    dashPort = str(args.dashport if args.dashport else randrange(8000,9999))
    rayApp = args.rayapp
    modelName = args.modelname
    dataPath = args.datapath
    cpusPerTrial = args.cpus_per_trial
    appArgs = args.app_args

    # Run job_runner with required flags from either argparse or yaml
    return_code = subprocess.call([jobRunner,resources,wallTime,runDir,port,
    redisPassword,str(cpusPerworker),nGpus,hostWriter,str(nProcesses),
    condaEnv,rayEnv,dashPort,rayApp,modelName,dataPath,cpusPerTrial,appArgs])

if __name__ == '__main__':
    main()
