# Builds a Docker image for Overture from github in a Desktop environment
# with Ubuntu and LXDE in parallel with PETSc 3.7.x.
#
# The image can be found at:
#   https://hub.docker.com/r/unifem/overture-desktop
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

# The installation procedure follows the (somewhat-oudated) Guide at
# See http://www.overtureframework.org/documentation/install.pdf

# Use meshdb-desktop as base image
FROM unifem/overture-desktop:framework
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER $DOCKER_USER

# Compile CG in parallel
ENV APlusPlus=$PXX_PREFIX/P++/install \
    PPlusPlus=$PXX_PREFIX/P++/install \
    HDF=/usr/local/hdf5-${HDF5_VERSION}-openmpi \
    Overture=$DOCKER_HOME/overture/Overture.par \
    PETSC_DIR=/usr/lib/petscdir/3.7 \
    PETSC_LIB=/usr/lib/x86_64-linux-gnu \
    CG=$DOCKER_HOME/overture/cg \
    CGBUILDPREFIX=$DOCKER_HOME/overture/cg.bin

RUN cd $CG && \
    make -j2 usePETSc=on OV_USE_PETSC_3=1 libCommon && \
    make -j2 usePETSc=on OV_USE_PETSC_3=1 cgad cgcns cgins cgasf cgsm cgmp && \
    mkdir -p $CGBUILDPREFIX/bin && \
    ln -s -f $CGBUILDPREFIX/*/bin/* $CGBUILDPREFIX/bin && \
    \
    echo "export PATH=$CGBUILDPREFIX/bin:\$PATH:." >> \
        $DOCKER_HOME/.profile

USER root
WORKDIR $DOCKER_HOME
