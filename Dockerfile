# Builds a Docker image for Overture from github in a Desktop environment
# with Ubuntu and LXDE in serial with PETSc 3.8.x.
#
# The built image can be found at:
#   https://hub.docker.com/r/unifem/overture-desktop
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

# The installation procedure follows the (somewhat-oudated) Guide at
# See http://www.overtureframework.org/documentation/install.pdf

# Use meshdb-desktop as base image
FROM unifem/overture-desktop:base
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

USER $DOCKER_USER

ENV XLIBS=/usr/lib/X11 \
    OpenGL=/usr \
    MOTIF=/usr \
    LAPACK=/usr/lib \
    \
    APlusPlus=$AXX_PREFIX/A++/install \
    HDF=/usr/local/hdf5-${HDF5_VERSION} \
    Overture=$DOCKER_HOME/overture/Overture.bin \
    PETSC_DIR=/usr/local/petsc-$PETSC_VERSION \
    PETSC_LIB=/usr/local/petsc-$PETSC_VERSION/lib

# Compile Overture framework in serial
RUN cd $DOCKER_HOME && \
    git clone --depth 1 -b next https://github.com/unifem/overtureframework.git overture && \
    perl -e 's/https:\/\/github.com\//git\@github.com:/g' -p -i $DOCKER_HOME/overture/.git/config && \
    \
    mkdir $DOCKER_HOME/cad && \
    cd overture/Overture && \
    OvertureBuild=$Overture ./buildOverture && \
    cd $Overture && \
    ./configure opt linux petsc && \
    make -j2 && \
    make rapsodi && \
    \
    echo "export PATH=$Overture/bin:\$PATH:." >> \
        $DOCKER_HOME/.profile

# Compile Overture framework in parallel
RUN export APlusPlus=$PXX_PREFIX/A++/install && \
    export PPlusPlus=$PXX_PREFIX/P++/install && \
    export HDF=/usr/local/hdf5-${HDF5_VERSION}-openmpi && \
    export Overture=$DOCKER_HOME/overture/Overture.par && \
    export PETSC_DIR=/usr/lib/petscdir/3.7.6/x86_64-linux-gnu-real && \
    export PETSC_LIB=/usr/lib/x86_64-linux-gnu && \
    \
    cd $DOCKER_HOME/overture/Overture && \
    OvertureBuild=$Overture ./buildOverture && \
    cd $Overture && \
    ./configure opt linux petsc parallel cc=mpicc bcc=gcc CC=mpicxx bCC=g++ FC=mpif90 bFC=gfortran && \
    make -j2 && \
    make rapsodi

WORKDIR $DOCKER_HOME
USER root
