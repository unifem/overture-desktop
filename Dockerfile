# Builds a Docker image for Overture from github in a Desktop environment
# with Ubuntu and LXDE in serial without PETSc.
#
# The built image can be found at:
#   https://hub.docker.com/r/unifem/overture-desktop
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

# The installation procedure follows the (somewhat-oudated) Guide at
# See http://www.overtureframework.org/documentation/install.pdf

# Use meshdb-desktop as base image
FROM unifem/meshdb-desktop
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Install compilers, openmpi, motif and mesa to prepare for overture
# Also install Atom for editing
RUN add-apt-repository ppa:webupd8team/atom && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      csh \
      build-essential \
      gfortran \
      openmpi-bin \
      libopenmpi-dev \
      \
      libmotif-dev \
      libgl1-mesa-dev \
      libglu1-mesa \
      libglu1-mesa-dev \
      \
      libperl-dev \
      \
      libxmu-dev \
      libxi-dev \
      x11proto-print-dev \
      \
      liblapack3 \
      liblapack-dev \
      \
      atom && \
    \
    curl -O http://ubuntu.cs.utah.edu/ubuntu/pool/main/libx/libxp/libxp6_1.0.2-1ubuntu1_amd64.deb && \
    dpkg -i libxp6_1.0.2-1ubuntu1_amd64.deb && \
    curl -O http://ubuntu.cs.utah.edu/ubuntu/pool/main/libx/libxp/libxp-dev_1.0.2-1ubuntu1_amd64.deb && \
    dpkg -i libxp-dev_1.0.2-1ubuntu1_amd64.deb && \
    \
    ln -s -f /usr/bin/make /usr/bin/gmake && \
    \
    ln -s -f /usr/lib/x86_64-linux-gnu /usr/lib64 && \
    ln -s -f /usr/lib/x86_64-linux-gnu/libX11.so /usr/lib/X11 && \
    \
    pip install -U autopep8 && \
    apm install \
        language-docker \
        autocomplete-python \
        git-plus \
        merge-conflicts \
        split-diff \
        platformio-ide-terminal \
        intentions \
        busy-signal \
        python-autopep8 \
        clang-format && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME && \
    \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER $DOCKER_USER
WORKDIR $DOCKER_HOME
ENV AXX_PREFIX=$DOCKER_HOME/overture/A++P++.bin

# Download Overture, A++ and P++; compile only A++
# Do not run "make check" to avoid timeout
RUN cd $DOCKER_HOME && \
    git clone --depth 1 -b next https://github.com/unifem/overtureframework.git overture && \
    perl -e 's/https:\/\/github.com\//git@github.com:/g' -p -i $DOCKER_HOME/overture/.git/config && \
    cd $DOCKER_HOME/overture && \
    cd A++P++ && \
    ./configure --enable-SHARED_LIBS --prefix=$AXX_PREFIX && \
    make -j2 && \
    make install

# Compile Overture framework
WORKDIR $DOCKER_HOME/overture

ENV APlusPlus=$AXX_PREFIX/A++/install \
    XLIBS=/usr/lib/X11 \
    OpenGL=/usr \
    MOTIF=/usr \
    HDF=/usr/local/hdf5-${HDF5_VERSION} \
    Overture=$DOCKER_HOME/overture/Overture.bin \
    LAPACK=/usr/lib

RUN cd $DOCKER_HOME/overture/Overture && \
    mkdir $DOCKER_HOME/cad && \
    OvertureBuild=$Overture ./buildOverture && \
    cd $Overture && \
    ./configure opt linux && \
    make -j2 && \
    make rapsodi

# Compile CG
ENV CG=$DOCKER_HOME/overture/cg
ENV CGBUILDPREFIX=$DOCKER_HOME/overture/cg.bin
RUN cd $CG && \
    make -j2 usePETSc=off libCommon && \
    make -j2 usePETSc=off cgad cgcns cgins cgasf cgsm cgmp && \
    mkdir -p $CGBUILDPREFIX/bin && \
    ln -s -f $CGBUILDPREFIX/*/bin/* $CGBUILDPREFIX/bin

RUN echo "export PATH=$Overture/bin:$CGBUILDPREFIX/bin:\$PATH:." >> \
        $DOCKER_HOME/.profile

WORKDIR $DOCKER_HOME
USER root
