# Builds a Docker image for Overture in a Desktop environment
# with Ubuntu and LXDE.
#
# The built image can be found at:
#   https://hub.docker.com/r/unifem/overture-desktop
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM compdatasci/spyder-desktop
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Install Overture and code-aster and petsc
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    	gfortran \
    	code-aster \
    	code-aster-mpi-engine \
    	code-aster-gui \
    	code-aster-run \
    	code-aster-test \
    	libpetsc3.6 && \
    echo "@codeaster-gui" >> $DOCKER_HOME/.config/lxsession/LXDE/autostar && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

########################################################
# Customization for user and location
########################################################

WORKDIR $DOCKER_HOME

USER root
