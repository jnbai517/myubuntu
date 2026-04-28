# This Dockerfile constructs an ubuntu docker image
# with common neuroimaging tools set up
#
# Author: Liu Mengxing 刘梦醒
# Contact: mengxing1844@gmail.com
# Modified: Added ParaView, MATLAB Runtime, MRIcron, DSI Studio, fMRIPrep, 3D Slicer
#
# Example build:
#   docker build --no-cache --tag lmengxing/myubuntu:0.4 .
#
# Example usage:
#   docker run -v /path/to/your/subject:/input /path/to/your/output:/output lmengxing/myubuntu:0.4
#   docker run lmengxing/myubuntu:0.4 3dinfo



# version log

# version: 0.4.2
# Updated: FSL 6.0.7.22 (matching host system version)
# Changed: Removed built-in license.txt (mount at runtime instead)
# Fixed: README commands updated for proper usage
# Added: ParaView 5.x (apt)
# Added: MATLAB Runtime R2024b (in addition to R2014b for FreeSurfer)
# Added: MRIcron (latest from GitHub)
# Added: DSI Studio 2025.04.16
# Added: fMRIPrep (pip install with dependencies)
# Added: 3D Slicer 5.8 (Stable)

# version: 0.3
# Base: Ubuntu 24.04.3 LTS (Noble Numbat)
# Added: FreeSurfer license.txt support
# Added: OpenClaw 2026.3.8

# version: 0.2
# support calling command through host command line

# version: 0.1
# Ubuntu version: 18.04

# common tools included:
# Freesurfer:   7.2.0
# ANTs:         2.4.0 SHA:04a018d
# AFNI:         AFNI_22.2.02 'Marcus Aurelius'
# MRtrix3:      3.0.3
# FSL:          6.0.7.22 
# OpenClaw:     2026.3.8
# ParaView:     5.x
# MATLAB Runtime: R2014b + R2024b
# MRIcron:      latest
# DSI Studio:   2025.04.16
# fMRIPrep:     latest (pip)
# 3D Slicer:    5.8.0







FROM ubuntu:noble-20241011


ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for all neuroimaging tools (Ubuntu 24.04)
RUN apt-get update && apt-get -y install \
        bc \
        tar \
        zip \
        wget \
        gawk \
        tcsh \
        libgomp1 \
        python3 \
        perl-modules \
        libxm4 \
        bzip2 \
        ca-certificates \
        libglib2.0-0 \
        libxext6 \
        libsm6 \
        libxrender1 \
        git \
        curl \
        grep \
        sed \
        dpkg \
        libxt6 \
        libxcomposite1 \
        libfontconfig1 \
        libasound2 \
        gcc \
        g++ \
        libeigen3-dev \
        zlib1g-dev \
        libgl1-mesa-dev \
        libfftw3-dev \
        libtiff-dev \
        xvfb \
        xfonts-100dpi \
        xfonts-75dpi \
        xfonts-cyrillic \
        unzip \
        imagemagick \
        jq \
        vim \
        python3-pip \
        libxt-dev \
        libxmu-dev \
        libglw1-mesa \
        libgsl-dev \
        qt6-base-dev \
        libqt6svg6 \
        ninja-build \
        cmake \
        software-properties-common \
        apt-transport-https \
        gnupg \
        build-essential \
        libssl3 \
        r-base \
        paraview \
        libxkbcommon-x11-0 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-randr0 \
        libxcb-render-util0 \
        libxcb-shape0 \
        libxcb-xfixes0 \
        libxcb-xinerama0 \
        libxcb-xkb1 \
        libxcb-cursor0 \
        libgl2ps1.4 \
        libopenblas-dev \
        libdcmtk-dev \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

# ============================================================
# FreeSurfer 7.2.0 Installation
# ============================================================
RUN wget -N -qO- ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.2.0/freesurfer-linux-ubuntu18_amd64-7.2.0.tar.gz | tar -xz -C /opt && chown -R root:root /opt/freesurfer && chmod -R a+rx /opt/freesurfer

# FreeSurfer License - mount your license.txt at runtime
# Run: docker run -v /path/to/license.txt:/opt/freesurfer/license.txt ...

RUN cat /opt/freesurfer/SetUpFreeSurfer.sh >> ~/.bashrc

# MATLAB R2014b Runtime (required by FreeSurfer)
ENV FREESURFER_HOME /opt/freesurfer
RUN wget -N -qO- "https://surfer.nmr.mgh.harvard.edu/fswiki/MatlabRuntime?action=AttachFile&do=get&target=runtime2014bLinux.tar.gz" | tar -xz -C $FREESURFER_HOME && chown -R root:root /opt/freesurfer/MCRv84 && chmod -R a+rx /opt/freesurfer/MCRv84

# ============================================================
# MATLAB Runtime R2024b (additional, for newer applications)
# ============================================================
RUN mkdir -p /opt/matlab_runtime && \
    wget -q https://ssd.mathworks.com/supportfiles/downloads/R2024b/Release/3/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2024b_Update_3_glnxa64.zip -O /tmp/matlab_runtime.zip && \
    unzip /tmp/matlab_runtime.zip -d /tmp/matlab_runtime && \
    /tmp/matlab_runtime/install -mode silent -agreeToLicense yes -destinationFolder /opt/matlab_runtime/R2024b && \
    rm -rf /tmp/matlab_runtime /tmp/matlab_runtime.zip

ENV MATLAB_RUNTIME_ROOT=/opt/matlab_runtime/R2024b
ENV LD_LIBRARY_PATH="$MATLAB_RUNTIME_ROOT/runtime/glnxa64:$MATLAB_RUNTIME_ROOT/bin/glnxa64:$MATLAB_RUNTIME_ROOT/sys/os/glnxa64:$LD_LIBRARY_PATH"

# ============================================================
# Python Dependencies
# ============================================================
RUN pip3 install --break-system-packages numpy nibabel scipy pandas dipy nipype

# ============================================================
# ANTs 2.4.0 Installation
# ============================================================
RUN wget -N -q "https://github.com/ANTsX/ANTs/archive/04a018d.zip"
RUN unzip 04a018d.zip && chmod -R a+rx ANTs-04a018dc5308183b455194a9a5b14ffe1b0edf5f/

RUN mkdir -p /tmp/ants/source/ && cp -r ANTs-04a018dc5308183b455194a9a5b14ffe1b0edf5f/* /tmp/ants/source/
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

ENV LD_LIBRARY_PATH="/opt/ants/lib:$LD_LIBRARY_PATH"
RUN cd /tmp/ants/build/ANTS-build && cmake --build . --target test

ENV ANTSPATH="/opt/ants/bin" \
    PATH="/opt/ants/bin:$PATH"

# ============================================================
# AFNI Installation
# ============================================================
RUN curl -O https://afni.nimh.nih.gov/pub/dist/bin/misc/@update.afni.binaries
RUN tcsh @update.afni.binaries -package linux_ubuntu_16_64 -do_extras
RUN echo 'export R_LIBS=$HOME/R' >> ~/.bashrc
RUN echo 'setenv R_LIBS ~/R' >> ~/.cshrc
RUN echo 'export PATH=$PATH:$HOME/abin' >> ~/.bashrc
RUN echo 'setenv PATH $PATH $HOME/abin' >> ~/.cshrc
ENV PATH="/root/abin/:$PATH"

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN /bin/bash -c "rPkgsInstall -pkgs ALL"

# ============================================================
# MRtrix3 Installation
# ============================================================
ARG MRTRIX3_GIT_COMMITISH="master"
ARG MRTRIX3_CONFIGURE_FLAGS=""
ARG MRTRIX3_BUILD_FLAGS="-persistent -nopaginate"
ARG MAKE_JOBS="8"

WORKDIR /opt/mrtrix3
RUN git clone -b $MRTRIX3_GIT_COMMITISH --depth 1 https://github.com/MRtrix3/mrtrix3.git . \
    && ./configure $MRTRIX3_CONFIGURE_FLAGS \
    && NUMBER_OF_PROCESSORS=$MAKE_JOBS ./build $MRTRIX3_BUILD_FLAGS \
    && rm -rf tmp
WORKDIR /root/
RUN cd /opt/mrtrix3/ && ./set_path

RUN mv /root/abin /opt/
ENV PATH=/opt/abin:/opt/mrtrix3:$PATH

# ============================================================
# FSL 6.0.7.22 Installation
# ============================================================
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py -O fslinstaller.py \
    && python3 fslinstaller.py -V 6.0.7.22 -d /opt/fsl 

ARG CACHEBUST=1 
ENV FSLDIR="/opt/fsl"
ENV PATH="$FSLDIR/bin:$PATH" \
    FSLMULTIFILEQUIT=TRUE \
    FSLGECUDAQ=cuda.q \
    FSLTCLSH="$FSLDIR/bin/fsltclsh" \
    FSLWISH="$FSLDIR/bin/fslwish" \
    FSLOUTPUTTYPE=testNIFTI_GZ

RUN rm fslinstaller.py && mkdir /root/work
RUN chmod -R 777 /root

# ============================================================
# ParaView Installation (via apt)
# ============================================================
# ParaView is already installed via apt in the first RUN command
# Create a symlink for easy access
RUN ln -sf /usr/bin/paraview /usr/local/bin/paraview

# ============================================================
# MRIcron Installation
# ============================================================
RUN mkdir -p /opt/mricron && \
    wget -q https://github.com/neurolabusc/MRIcron/releases/download/v1.0.20220106/MRIcron_linux64.tgz -O /tmp/mricron.tgz && \
    tar -xzf /tmp/mricron.tgz -C /opt/mricron --strip-components=1 && \
    chmod +x /opt/mricron/mricron /opt/mricron/dcm2niix /opt/mricron/npm && \
    rm /tmp/mricron.tgz

ENV PATH="/opt/mricron:$PATH"

# ============================================================
# DSI Studio Installation
# ============================================================
RUN mkdir -p /opt/dsi_studio && \
    wget -q https://github.com/frankyeh/DSI-Studio/releases/download/2025.04.16/dsi_studio_ubuntu2404.tar.gz -O /tmp/dsi_studio.tar.gz && \
    tar -xzf /tmp/dsi_studio.tar.gz -C /opt/dsi_studio --strip-components=1 && \
    chmod +x /opt/dsi_studio/dsi_studio && \
    rm /tmp/dsi_studio.tar.gz

ENV PATH="/opt/dsi_studio:$PATH"

# ============================================================
# 3D Slicer Installation
# ============================================================
RUN mkdir -p /opt/slicer && \
    wget -q "https://download.slicer.org/bitstream/6911b598ac7b1c95e7934427" -O /tmp/slicer.tar.gz && \
    tar -xzf /tmp/slicer.tar.gz -C /opt/slicer --strip-components=1 && \
    rm /tmp/slicer.tar.gz

ENV PATH="/opt/slicer/Slicer-5.8.0-linux-amd64:$PATH"
ENV SLICER_HOME="/opt/slicer"

# ============================================================
# fMRIPrep Installation (bare-metal)
# ============================================================
# Install additional dependencies required by fMRIPrep
RUN pip3 install --break-system-packages fmriprep fmriprep-docker bids-validator

# ============================================================
# OpenClaw Installation
# ============================================================
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

RUN node --version && npm --version

RUN npm install -g openclaw@2026.3.8

ENV OPENCLAW_HOME=/root/.openclaw
ENV PATH="$PATH:/root/.npm-global/bin"

RUN mkdir -p $OPENCLAW_HOME/agents/main \
    && mkdir -p $OPENCLAW_HOME/skills \
    && mkdir -p $OPENCLAW_HOME/workspace

RUN openclaw status || true

RUN openclaw skill install aistore \
    && openclaw skill install summarize \
    && openclaw skill install tavily-search \
    && openclaw skill install find-skills \
    && openclaw skill install self-improving \
    && openclaw skill install skill-vetter

# ============================================================
# Environment Variables
# ============================================================
ENV PATH="$PATH:/opt/freesurfer/bin:/opt/mrtrix3/bin:/opt/mricron:/opt/dsi_studio:/opt/slicer/Slicer-5.8.0-linux-amd64"

# Expose OpenClaw Gateway port
EXPOSE 18789

# OpenClaw health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD openclaw status || exit 1

#ENTRYPOINT /bin/bash
