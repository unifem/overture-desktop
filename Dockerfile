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
ENV APlusPlus=$AXX_PREFIX/A++/install \
    XLIBS=/usr/lib/X11 \
    OpenGL=/usr \
    MOTIF=/usr \
    HDF=/usr/local/hdf5-${HDF5_VERSION} \
    Overture=$DOCKER_HOME/overture/Overture.bin \
    LAPACK=/usr/lib \
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
        $DOCKER_HOME/.profile && \
    echo "export LD_LIBRARY_PATH=$APlusPlus/lib:$Overture/lib:\$LD_LIBRARY_PATH" >> \
        $DOCKER_HOME/.profile

WORKDIR $DOCKER_HOME
USER root
