# This Dockerfile constructs an ubuntu docker image
# with common neuroimaging tools set up
#
# Author: Liu Mengxing 刘梦醒
# Contact: mengxing1844@gmail.com
# Modified: Added FreeSurfer license and OpenClaw support
#
# Example build:
#   docker build --no-cache --tag lmengxing/myubuntu:0.3 .
#
# Example usage:
#   docker run -v /path/to/your/subject:/input /path/to/your/output:/output lmengxing/myubuntu:0.3
#   docker run lmengxing/myubuntu:0.3 3dinfo



# version log

# version: 0.3
# Added: FreeSurfer license.txt support (COPY license.txt to /opt/freesurfer/)
# Added: OpenClaw 2026.3.8 with Node.js 22.x
# Base: Ubuntu 18.04 (for neuroimaging tools compatibility)

# version: 0.2
# support calling command through host command line

# version: 0.1
# Ubuntu version: 18.04

# common tools included:
# Freesurfer:   7.2.0
# ANTs:         2.4.0 SHA:04a018d
# AFNI:         AFNI_22.2.02 'Marcus Aurelius'
# MRtrix3:      3.0.3
# FSL:          6.0.6 
# OpenClaw:     2026.3.8 (NEW)







FROM ubuntu:bionic-20220427


ENV DEBIAN_FRONTEND=noninteractive
# Install dependencies for FreeSurfer
RUN apt-get update && apt-get -y install \
        bc \
        tar \
        zip \
        wget \
        gawk \
        tcsh \
        libgomp1 \
        python2.7 \
        python3 \
        perl-modules \
        libxm4

# Download Freesurfer 7.2 from MGH and untar to /opt
RUN wget -N -qO- ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.2.0/freesurfer-linux-ubuntu18_amd64-7.2.0.tar.gz | tar -xz -C /opt && chown -R root:root /opt/freesurfer && chmod -R a+rx /opt/freesurfer

# ============================================================
# FreeSurfer License - COPY your license.txt to the container
# ============================================================
# You need to have license.txt in the build context
# Get your license from: https://surfer.nmr.mgh.harvard.edu/registration.html
COPY license.txt /opt/freesurfer/license.txt

RUN apt-get update --fix-missing \
 && apt-get install -y bzip2 ca-certificates \
      libglib2.0-0 libxext6 libsm6 libxrender1 \
      git mercurial subversion curl grep sed dpkg \
      libxt6 libxcomposite1 libfontconfig1 libasound2 \
      gcc g++ libeigen3-dev zlib1g-dev libgl1-mesa-dev libfftw3-dev libtiff5-dev \
      xvfb xfonts-100dpi xfonts-75dpi xfonts-cyrillic \
      unzip imagemagick jq vim python3-pip libxt-dev libxmu-dev 

RUN cat /opt/freesurfer/SetUpFreeSurfer.sh >> ~/.bashrc

############################
# The brainstem and hippocampal subfield modules in FreeSurfer-dev require the Matlab R2014b runtime

ENV FREESURFER_HOME /opt/freesurfer
RUN wget -N -qO- "https://surfer.nmr.mgh.harvard.edu/fswiki/MatlabRuntime?action=AttachFile&do=get&target=runtime2014bLinux.tar.gz" | tar -xz -C $FREESURFER_HOME && chown -R root:root /opt/freesurfer/MCRv84 && chmod -R a+rx /opt/freesurfer/MCRv84

RUN pip3 install numpy nibabel scipy pandas 

# Compile and configure ANTs
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
                    apt-transport-https \
                    build-essential \
                    ca-certificates \
                    gnupg \
                    ninja-build \
                    software-properties-common \
                    zlib1g-dev libssl1.1
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null \
    | apt-key add - \
  && apt-add-repository -y 'deb https://apt.kitware.com/ubuntu/ bionic main' \
  && apt-get update \
  && apt-get -y install cmake=3.18.3-0kitware1 cmake-data=3.18.3-0kitware1
RUN wget -N -q "https://github.com/ANTsX/ANTs/archive/04a018d.zip"
RUN unzip 04a018d.zip && chmod -R a+rx ANTs-04a018dc5308183b455194a9a5b14ffe1b0edf5f/

RUN mkdir -p /tmp/ants/source/ && cp -r ANTs-04a018dc5308183b455194a9a5b14ffe1b0edf5f/* /tmp/ants/source/
RUN ls /tmp/ants/source/*
RUN mkdir -p /tmp/ants/build \
    && cd /tmp/ants/build \
    && mkdir -p /opt/ants \
    && git config --global url."https://".insteadOf git:// \
    && cmake \
      -GNinja \
      -DBUILD_TESTING=ON \
      -DRUN_LONG_TESTS=OFF \
      -DRUN_SHORT_TESTS=ON \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_INSTALL_PREFIX=/opt/ants \
      /tmp/ants/source \
    && cmake --build . --parallel \
    && cd ANTS-build \
    && cmake --install .
# Need to set library path to run tests
ENV LD_LIBRARY_PATH="/opt/ants/lib:$LD_LIBRARY_PATH"

RUN cd /tmp/ants/build/ANTS-build \
    && cmake --build . --target test

ENV ANTSPATH="/opt/ants/bin" \
    PATH="/opt/ants/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/ants/lib:$LD_LIBRARY_PATH"
RUN apt-get update \
    && apt install -y --no-install-recommends \
                   zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Compile and configure AFNI 
RUN ln -s /usr/lib/x86_64-linux-gnu/libgsl.so.23 /usr/lib/x86_64-linux-gnu/libgsl.so.19
RUN curl -O https://afni.nimh.nih.gov/pub/dist/bin/misc/@update.afni.binaries
RUN tcsh @update.afni.binaries -package linux_ubuntu_16_64 -do_extras
RUN echo  'export R_LIBS=$HOME/R' >> ~/.bashrc
RUN echo  'setenv R_LIBS ~/R'     >> ~/.cshrc
RUN echo 'export PATH=$PATH:$HOME/abin' >> ~/.bashrc
RUN echo 'setenv PATH $PATH:$HOME/abin' >> ~/.cshrc
ENV PATH="/root/abin/:$PATH"
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
    && add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/' \
    && apt update 
RUN apt install -y r-base

RUN /bin/bash -c "rPkgsInstall -pkgs ALL"


# Compile and configure mrtrix 3
# Git commitish from which to build MRtrix3.
ARG MRTRIX3_GIT_COMMITISH="master"
# Command-line arguments for `./configure`
ARG MRTRIX3_CONFIGURE_FLAGS=""
# Command-line arguments for `./build`
ARG MRTRIX3_BUILD_FLAGS="-persistent -nopaginate"

ARG MAKE_JOBS="8"
WORKDIR /opt/mrtrix3
RUN apt install -y qt5-default libqt5svg5*
RUN git clone -b $MRTRIX3_GIT_COMMITISH --depth 1 https://github.com/MRtrix3/mrtrix3.git . \
    && ./configure $MRTRIX3_CONFIGURE_FLAGS \
    && NUMBER_OF_PROCESSORS=$MAKE_JOBS ./build $MRTRIX3_BUILD_FLAGS \
    && rm -rf tmp
WORKDIR /root/
RUN cd /opt/mrtrix3/ && ./set_path
# move AFNI to /opt/
RUN mv /root/abin /opt/
ENV PATH=/opt/abin:/opt/mrtrix3:$PATH

# install FSL version 6.0.6
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py -O fslinstaller.py \
    && python fslinstaller.py -V 6.0.6 -d /opt/fsl 
ARG CACHEBUST=1 
ENV FSLDIR="/opt/fsl"
ENV PATH="$FSLDIR/bin:$PATH" \
    FSLMULTIFILEQUIT=TRUE \
    FSLGECUDAQ=cuda.q \
    FSLTCLSH="$FSLDIR/bin/fsltclsh" \
    FSLWISH="$FSLDIR/bin/fslwish" \
    FSLOUTPUTTYPE=testNIFTI_GZ \
    PATH="$PATH:/opt/freesurfer/bin"
RUN rm fslinstaller.py && mkdir /root/work
RUN apt install libglw1-mesa
RUN chmod -R 777 /root
ENV PATH="$PATH:/opt/freesurfer/bin:/opt/mrtrix3/bin"


# ============================================================
# OpenClaw Installation
# ============================================================
# Install Node.js 22.x (required for OpenClaw)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# Verify Node.js and npm versions
RUN node --version && npm --version

# Install OpenClaw globally
RUN npm install -g openclaw@2026.3.8

# Set OpenClaw environment variables
ENV OPENCLAW_HOME=/root/.openclaw
ENV PATH="$PATH:/root/.npm-global/bin"

# Create OpenClaw directories
RUN mkdir -p $OPENCLAW_HOME/agents/main \
    && mkdir -p $OPENCLAW_HOME/skills \
    && mkdir -p $OPENCLAW_HOME/workspace

# Initialize OpenClaw (creates default config)
RUN openclaw status || true

# Install useful OpenClaw skills
RUN openclaw skill install aistore \
    && openclaw skill install summarize \
    && openclaw skill install tavily-search \
    && openclaw skill install find-skills \
    && openclaw skill install self-improving \
    && openclaw skill install skill-vetter

# Expose OpenClaw Gateway port
EXPOSE 18789

# OpenClaw health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD openclaw status || exit 1


#ENTRYPOINT /bin/bash 
