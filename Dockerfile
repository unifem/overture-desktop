# Builds a Docker image for the base of Overture in a Desktop environment
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

# Build HDF5-1.8.20 from source both in serial and parallel
# HDF5-1.10.x in Ubuntu 17.10 is incompatible with Overture
ENV HDF5_VERSION=1.8.20
RUN cd /tmp && \
    curl -L https://support.hdfgroup.org/ftp/HDF5/current18/src/hdf5-${HDF5_VERSION}.tar.gz | \
        tar zx && \
    cd hdf5-${HDF5_VERSION} && \
    ./configure --enable-shared --prefix /usr/local/hdf5-${HDF5_VERSION} && \
    make -j2 && make install && \
    \
    make clean && \
    ./configure --enable-shared --enable-parallel --prefix /usr/local/hdf5-${HDF5_VERSION}-openmpi && \
    make -j2 && make install && \
    \
    rm -rf /tmp/*

USER $DOCKER_USER
WORKDIR $DOCKER_HOME
ENV AXX_PREFIX=$DOCKER_HOME/A++P++.bin
ENV PXX_PREFIX=$DOCKER_HOME/A++P++

# Download A++ and P++; compile A++ and P++
# Note that P++ must be in the source tree, or Overture would fail to compile
RUN cd $DOCKER_HOME && \
    git clone --depth 1 https://github.com/unifem/aplusplus.git A++P++ && \
    cd A++P++ && \
    ./configure --enable-SHARED_LIBS --prefix=$AXX_PREFIX && \
    make -j2 && \
    make install && \
    \
    export MPI_ROOT=/usr/lib/x86_64-linux-gnu/openmpi && \
    ./configure --enable-PXX --prefix=$PXX_PREFIX --enable-SHARED_LIBS \
       --with-mpi-include="-I${MPI_ROOT}/include" \
       --with-mpi-lib-dirs="-Wl,-rpath,${MPI_ROOT}/lib -L${MPI_ROOT}/lib" \
       --with-mpi-libs="-lmpi -lmpi_cxx" \
       --with-mpirun=/usr/bin/mpirun \
       --without-PADRE && \
    make -j2 && \
    make install

WORKDIR $DOCKER_HOME
USER root
