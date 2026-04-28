# MyUbuntu for neuroimaging analysis


myubuntu is a docker container based on Ubuntu 18.04 LTS. Several common neuroimaging softwares are installed and ready to use.

It also contains R and Python2/3 for basic computations. And they can be called by other neuroimaging analysis tools (e.g. 3dMVM requires R for ANOVA analysis).

## When do you need this container:
 
* You work with Windows.
  
* You have trouble with installation/configuration of specific neuroimaging softwares.
  
* You work with high performance computer(HPC) which does not allow you to install your libraries freely.
  
* You want a clean/stable/reproducible computing environment.

## If you want to cite this work: 
* cff-version: 1.2.0
* title: "Neuroimaging Tools Docker Container"
* authors:
 - Liu Mengxing

* version: "0.3"
* date-released: "2026-04-28"
* DOI:10.5281/zenodo.17559245

## *Full list of main software and version:*

* Freesurfer:      7.2.0 (with license.txt)
* ANTs:            2.4.0 SHA:04a018d
* AFNI:            AFNI_22.2.02 'Marcus * Aurelius'
* MRtrix3:         3.0.3
* FSL:             6.0.6
* Python:          2.7.17/3.6.9
* R:               3.6.3
* MATLAB Runtime:  2014b(8.4)
* **OpenClaw:      2026.3.8 (NEW in v0.3)**
  
## *Installation*

There are two ways to install this container on your personal machine or high performance computer(HPC)

### A. Build from Dockerfile

To build the container from Dockerfile, you should have docker engine installed on your machine.

**Important:** You need to place your FreeSurfer `license.txt` file in the same directory as the Dockerfile before building.

    $ git clone https://github.com/jnbai517/myubuntu.git
    $ cd myubuntu/
    # Copy your FreeSurfer license.txt here
    $ cp /path/to/your/license.txt ./
    $ docker build -t myubuntu:0.3 .

This usually takes 2-3 hours, as building from Dockerfile basically equals compiling the softwares from fresh. 

**Please be alert**, if you choose to build from Dockerfile, some dependencies might be installed as the latest version by your installation time (e.g. some libraries). But the neuroimaging tools will be in the exact same version as shown above.

### B. Pull from docker hub

If you choose to pull the container from docker hub instead of building from Dockerfile, you can have either **docker** or **singularity** installed on your machine (as some HPCs do not allow docker usage, singularity is a good alternative).

Pulling with **Docker**:

    $ docker pull lmengxing/myubuntu:0.3

Pulling with **Singularity**:

    $ singularity build myubuntu_0.3.sif docker://lmengxing/myubuntu:0.3


## *Usage*

The idea of this container is to provide a neuroimaging environment that allows users to run data analysis with their own data and pipeline interactively.

Simplest example:

Running with **Docker**:

    $ docker run -it lmengxing/myubuntu:0.3

or 

    $ sudo docker run -it lmengxing/myubuntu:0.3  # depends on your user permission

Running with **Singularity**:

    $ singularity shell myubuntu_0.3.sif


Formal usage example:

Usually you would like to mount your data on the container, in order to access and process your data after you enter the docker container environment. In MyUbuntu, there is a directory "work" under the home directory /root, where you can mount your data on.

Running with **Docker**:

    $ docker run -it -v /home/username/project:/root/work lmengxing/myubuntu:0.3
    $ docker run lmengxing/myubuntu:0.3 3dinfo

Running with **Singularity**:

    $ singularity shell --bind /home/username/project:/root/work myubuntu_0.3.sif

With this command, after you enter the docker container, you will find your data under /root/work. You can also try to mount multiple directories on your host to multiple destinations in the docker container, even the directories do not exist in the docker container before mounting.


## *Using GUI with myubuntu*

Linux:

Simple way is to forward X11 to your local machine so that the container can render to the correct display by reading and writing through the X11 unix socket.

First adjust the permission X server host with 

    $ xhost +local:root # this adds the container username to your x server access list

This is not safe as someone could display something on your screen (although not likely).

After adding access, you can run myubuntu with a few more parameters:

    sudo docker run --rm -ti \
        --user=0 \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -e DISPLAY=${DISPLAY} \
        lmengxing/myubuntu:0.3 /bin/bash

Once you finish your work, and if you are concerned about the X server host security, you can remove "root" from your access list by:

    xhost -local:root

MacOS:

    Coming...

Windows:

    Use VcXsrv. This method is not stable, fsleyes in my computer will report an error (added and tested by @Ernest861)

1. Install VcXsrv Windows X Server (path a or b is same),

    a. download exe and install（[https://sourceforge.net/projects/vcxsrv/]);
    b. **OR** use Chocolatey to install ([https://chocolatey.org/install]).

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install vcxsrv
```

2. Set XLaunch
    2.1 run Xlaunch from the start menu;
    2.2 Display settings: Multiple windows and Display number -1;
    2.3 Client startup: Start no client;
    2.4 Extra settings: √Clipboard-Primary Selection, Native opengl, disable access control;
    2.5 if Firewall alarm just allows.

3. Open Docker
    3.1 get local host ip; 3.2 run docker; 3.3 set DISPLAY value; 3.4 open freesurfer.

```PowerShell
ipconfig
docker run -it -v YOURWORKPATH:/root/work lmengxing/myubuntu:0.3
```
```Bash
export DISPLAY='YOURIP:0.0'
freeview
```
This method is not stable in some Windows 10 setups and seems to be related to the AMD graphics (libGL error: No matching fbConfigs or visuals found
libGL error: failed to load driver: swrast).

## *OpenClaw Usage (NEW in v0.3)*

OpenClaw is an AI assistant framework that can help with neuroimaging workflows. It comes pre-installed with useful skills.

Check OpenClaw status:

    $ openclaw status

Start OpenClaw Gateway:

    $ openclaw gateway start

Available skills (pre-installed):
- `aistore` - AI Store integration
- `summarize` - Summarize URLs and documents
- `tavily-search` - AI-optimized web search
- `find-skills` - Discover new skills
- `self-improving` - Self-reflection capabilities
- `skill-vetter` - Security-first skill vetting

Install additional skills:

    $ openclaw skill install <skill-name>

OpenClaw documentation: https://docs.openclaw.ai

## *FreeSurfer License*

FreeSurfer requires a license file. In version 0.3+, the license is built into the image.

**To get your FreeSurfer license:**
1. Register at: https://surfer.nmr.mgh.harvard.edu/registration.html
2. Download your `license.txt`
3. Place it in the same directory as the Dockerfile before building

If you already have a container and need to use a different license:

    $ docker run -it -v /path/to/license.txt:/opt/freesurfer/license.txt lmengxing/myubuntu:0.3

## *Contributing*

Thank you for your interest in contributing to *MyUbuntu*! If you would like to have specific tools added in this container, feel free to open an issue. Or better, you can fork this repository and add the tools you like and do a pull request. 

Enjoy.