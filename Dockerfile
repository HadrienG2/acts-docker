# Configure the container's basic properties
FROM hgrasland/root-tests:latest-cxx14
LABEL Description="openSUSE Tumbleweed with ACTS installed" Version="0.1"
CMD bash
ARG ACTS_BUILD_TYPE=RelWithDebInfo

# Switch to a development branch of Spack with an updated ACTS package
#
# FIXME: This will need to be adapted when the ROOT image moves to a different
#        version of ROOT recipe and the HadrienG2 remote is not around anymore.
#        Ultimately, everything will be upstreamed, and we can remove this.
#
RUN cd /opt/spack                                                              \
    && git fetch HadrienG2                                                     \
    && git checkout HadrienG2/acts-package

# Install acts-core
RUN spack install acts-core@develop build_type=${ACTS_BUILD_TYPE} +examples    \
                                    +legacy +tests +integration_tests          \
                                    +material_plugin +tgeo                     \
                  ^ ${ROOT_SPACK_SPEC}

# Prepare the environment for using ACTS
RUN echo "spack load acts-core" >> "$SETUP_ENV"

# TODO: Install acts-framework, once it is in a buildable state again
