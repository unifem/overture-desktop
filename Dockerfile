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

# Install compilers, openmpi, motif and mesa to prepare for Overture
# Also install Atom for editing
RUN add-apt-repository ppa:webupd8team/atom && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      atom && \
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
ENV APlusPlus=$AXX_PREFIX/A++/install \
    XLIBS=/usr/lib/X11 \
    OpenGL=/usr \
    MOTIF=/usr \
    HDF=/usr/local/hdf5-${HDF5_VERSION} \
    Overture=$DOCKER_HOME/overture/Overture.bin \
    LAPACK=/usr/lib \
    PETSC_DIR=/usr/local/petsc-$PETSC_VERSION \
    PETSC_ARCH=linux-gnu-opt \
    PETSC_LIB=/usr/local/petsc-$PETSC_VERSION/lib

# Compile Overture framework
RUN cd $DOCKER_HOME && \
    git clone --depth 1 https://github.com/unifem/overtureframework.git overture && \
    perl -e 's/https:\/\/github.com\//git@github.com:/g' -p -i $DOCKER_HOME/overture/.git/config && \
    \
    mkdir $DOCKER_HOME/cad && \
    cd overture/Overture && \
    OvertureBuild=$Overture ./buildOverture && \
    cd $Overture && \
    ./configure opt linux petsc && \
    make -j2 && \
    make rapsodi

# Compile CG
ENV CG=$DOCKER_HOME/overture/cg
ENV CGBUILDPREFIX=$DOCKER_HOME/overture/cg.bin
RUN cd $DOCKER_HOME/overture && \
    \
    cd $CG && \
    make -j2 usePETSc=on OV_USE_PETSC_3=1 libCommon && \
    make -j2 usePETSc=on OV_USE_PETSC_3=1 cgad cgcns cgins cgasf cgsm cgmp && \
    mkdir -p $CGBUILDPREFIX/bin && \
    ln -s -f $CGBUILDPREFIX/*/bin/* $CGBUILDPREFIX/bin

RUN echo "export PATH=$Overture/bin:$CGBUILDPREFIX/bin:\$PATH:." >> \
        $DOCKER_HOME/.profile && \
    echo "export LD_LIBRARY_PATH=$APlusPlus/lib:$Overture/lib:$CG/cns/lib:$CG/ad/lib:$CG/asf/lib:$CG/ins/lib:$CG/common/lib:$CG/sm/lib:$CG/mp/lib:\$LD_LIBRARY_PATH" >> \
        $DOCKER_HOME/.profile

WORKDIR $DOCKER_HOME
USER root
