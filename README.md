# raytuneLSF

Python wrapper for starting distributed Ray clusters with LSF job submission.

## Requirements
ray == 1.4.1 <br>

## Getting started
Clone repo and cd into the project directory

```
$ conda create -n rayenv ray=1.4.1
$ conda activate rayenv
$ git clone https://github.com/oaoni/raytuneLSF.git
$ cd raytuneLSF
```

Run demo ray application: 

#### Local

```
$ python ray_app.py -L
```

![Ray Local](demo/local_ray.png)

#### Distributed via LSF job submission

```
$ python run_job.py\
 -j RayJob\
 --nworkers 2\
 --cpusperworker 2\
 --mempercpu "4"\
 --walltime "0:20"
```

![Ray Distributed](demo/distributed_ray.png)
