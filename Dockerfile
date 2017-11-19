# Builds a Docker image for Overture v26 in a Desktop environment
# with Ubuntu and LXDE.
#
# The built image can be found at:
#   https://hub.docker.com/r/unifem/overture-desktop
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

# The installation procedure follows the (somewhat-oudated) Guide at
# See http://www.overtureframework.org/documentation/install.pdf

FROM compdatasci/spyder-desktop:latest
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Install compilers, openmpi, motif, mesa, and hdf5
RUN apt-get update && \
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
      libhdf5-100 \
      libhdf5-dev \
      libhdf5-openmpi-100 \
      libhdf5-openmpi-dev \
      hdf5-tools \
      libperl-dev \
      \
      libxmu-dev \
      libxi-dev \
      x11proto-print-dev \
      \
      liblapack3 \
      liblapack-dev && \
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
    mkdir -p /usr/lib/hdf5-openmpi && \
    ln -s -f /usr/include/hdf5/openmpi /usr/lib/hdf5-openmpi/include && \
    ln -s -f /usr/lib/x86_64-linux-gnu/hdf5/openmpi /usr/lib/hdf5-openmpi/lib && \
    \
    mkdir -p /usr/lib/hdf5-serial && \
    ln -s -f /usr/include/hdf5/serial /usr/lib/hdf5-serial/include && \
    ln -s -f /usr/lib/x86_64-linux-gnu/hdf5/serial /usr/lib/hdf5-serial/lib && \
    \
    ln -s -f /usr/lib/x86_64-linux-gnu/libX11.so /usr/lib/X11


USER $DOCKER_USER
ENV APlusPlus_VERSION=0.8.2

# Download and compile A++ and P++
RUN mkdir -p $DOCKER_HOME/overture && cd $DOCKER_HOME/overture && \
    curl -L http://overtureframework.org/software/AP-$APlusPlus_VERSION.tar.gz | tar zx && \
    cd A++P++-$APlusPlus_VERSION && \
    ./configure --enable-SHARED_LIBS --prefix=`pwd` && \
    make -j2 && \
    make install && \
    make check && \
    \
    export MPI_ROOT=/usr/lib/x86_64-linux-gnu/openmpi && \
    ./configure --enable-PXX --prefix=`pwd` --enable-SHARED_LIBS \
       --with-mpi-include="-I${MPI_ROOT}/include" \
       --with-mpi-lib-dirs="-Wl,-rpath,${MPI_ROOT}/lib -L${MPI_ROOT}/lib" \
       --with-mpi-libs="-lmpi -lmpi_cxx" \
       --with-mpirun=/usr/bin/mpirun \
       --without-PADRE && \
    make -j2 && \
    make install && \
    make check

ENV APlusPlus=$DOCKER_HOME/overture/A++P++-$APlusPlus_VERSION/A++/install \
    PPlusPlus=$DOCKER_HOME/overture/A++P++-$APlusPlus_VERSION/P++/install \
    XLIBS=/usr/lib/X11 \
    OpenGL=/usr \
    MOTIF=/usr \
    HDF=/usr/lib/hdf5-serial \
    Overture=$DOCKER_HOME/overture/Overture.v26 \
    CG=$DOCKER_HOME/overture/cg.v26 \
    LAPACK=/usr/lib

WORKDIR $DOCKER_HOME/overture

# Download and compile Overture framework
# Note that the "distribution=ubuntu" command-line option breaks the
# configure script, so we need to hard-code it
RUN cd $DOCKER_HOME/overture && \
    git clone --depth 1 https://github.com/unifem/overture.git Overture.v26 && \
    \
    cd Overture.v26 && \
    sed -i -e 's/$distribution=""/$distribution="ubuntu"/g' ./configure && \
    ./configure opt --disable-X11 --disable-gl && \
    make -j2 && \
    make rapsodi && \
    ./check.p

# Download and compile CG without Maxwell equations
RUN cd $DOCKER_HOME/overture && \
    curl -L http://overtureframework.org/software/cg.v26.tar.gz | tar zx && \
    cd $CG && \
    make -j2 libCommon cgad cgcns cgins cgasf cgsm cgmp unitTests

USER root
