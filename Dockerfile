# Builds a Docker image for Overture in a Desktop environment
# with Ubuntu and LXDE.
#
# The built image can be found at:
#   https://hub.docker.com/r/unifem/overture-desktop

# The installation procedure follows the (somewhat-oudated) Guide at
# See http://www.overtureframework.org/documentation/install.pdf

FROM unifem/overture-desktop:framework
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root

# Download and compile CG
ENV CG=$DOCKER_HOME/overture/cg.v26

RUN cd $DOCKER_HOME/overture && \
    curl -L http://overtureframework.org/software/cg.v26.tar.gz | tar zx && \
    cd $DOCKER_HOME/overture/cg.v26 && \
    make && (make check || true)

USER root
