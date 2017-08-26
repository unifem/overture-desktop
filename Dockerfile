# Builds a Docker image for Overture in a Desktop environment
# with Ubuntu and LXDE.
#
# The built image can be found at:
#   https://hub.docker.com/r/unifem/overture-desktop
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

# The installation procedure follows the (somewhat-oudated) Guide at
# See http://www.overtureframework.org/documentation/install.pdf

FROM compdatasci/spyder-desktop
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Install compilers, mpich, motif, mesa, and hdf5
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      csh \
      build-essential \
    	gfortran \
      mpich \
      libmpich-dev \
      \
      libmotif-dev \
      libgl1-mesa-dev \
      libglu1-mesa \
      libglu1-mesa-dev \
      \
      libhdf5-10 \
      libhdf5-dev \
      libperl-dev \
      \
      libxmu-dev \
      libxi-dev \
      x11proto-print-dev \
      \
      liblapack3 \
      liblapack-dev \
      hdf5-tools && \
    \
    curl -O http://ubuntu.cs.utah.edu/ubuntu/pool/main/libx/libxp/libxp6_1.0.2-1ubuntu1_amd64.deb && \
    dpkg -i libxp6_1.0.2-1ubuntu1_amd64.deb && \
    curl -O http://ubuntu.cs.utah.edu/ubuntu/pool/main/libx/libxp/libxp-dev_1.0.2-1ubuntu1_amd64.deb && \
    dpkg -i libxp-dev_1.0.2-1ubuntu1_amd64.deb && \
    \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    \
    ln -s -f /usr/bin/make /usr/bin/gmake && \
    \
    mkdir /usr/local/hdf5-serial && \
    ln -s -f /usr/include/hdf5/serial /usr/local/hdf5-serial/include && \
    ln -s -f /usr/lib/x86_64-linux-gnu/hdf5/serial /usr/local/hdf5-serial/lib && \
    mkdir -p /usr/local/X11/lib && \
    ln -s -f /usr/lib/x86_64-linux-gnu/libX11.so /usr/local/X11/lib


USER $DOCKER_USER
ENV APlusPlus_VERSION=0.8.2

# Download and compile A++ and P++
RUN mkdir -p $DOCKER_HOME/overture && cd $DOCKER_HOME/overture && \
    curl -L http://overtureframework.org/software/AP-$APlusPlus_VERSION.tar.gz | tar zx && \
    cd A++P++-$APlusPlus_VERSION && \
    ./configure --enable-SHARED_LIBS --prefix=`pwd` && \
    make -j2 && \
    make install && \
    ./configure --enable-PXX --prefix=`pwd` --enable-SHARED_LIBS \
       --with-mpich=/usr/lib/mpich --without-PADRE && \
    make -j2 && \
    make install

ENV APlusPlus=$DOCKER_HOME/overture/A++P++-$APlusPlus_VERSION/A++/install \
    PPlusPlus=$DOCKER_HOME/overture/A++P++-$APlusPlus_VERSION/P++/install \
    XLIBS=/usr/local/X11 \
    OpenGL=/usr \
    MOTIF=/usr \
    HDF=/usr/local/hdf5-serial \
    Overture=$DOCKER_HOME/overture/Overture.v26 \
    CG=$DOCKER_HOME/overture/cg.v26 \
    LAPACK=/usr/lib

WORKDIR $DOCKER_HOME/overture

# Download and compile Overture and CG
# Note that the "distribution=ubuntu" command-line option breaks the
# configure script, so we need to hard-code it
RUN cd $DOCKER_HOME/overture && \
    curl -L http://overtureframework.org/software/cg.v26.tar.gz | tar zx && \
    curl -L http://overtureframework.org/software/Overture.v26.tar.gz | tar zx && \
    \
    cd Overture.v26 && \
    sed -i -e 's/$distribution=""/$distribution="ubuntu"/g' ./configure && \
    ./configure opt && \
    make -j2 && \
    make rapsodi

# Download and compile Overture and CG
# Note that the "distribution=ubuntu" command-line option breaks the
# configure script, so we need to hard-code it
RUN cd $DOCKER_HOME/overture/cg.v26 && \
    make

# Run additional checking. We disable them because it takes too long
#RUN cd $DOCKER_HOME/overture/A++P++-$APlusPlus_VERSION && make check && \
#    make checkcd $DOCKER_HOME/overture/Overture.v26 && ./check.p && \
#    cd $DOCKER_HOME/overture/cg.v26 && make check

USER root
