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

# This is the variant of the ACTS package which we are going to build
#
# TODO: Add DD4hep plugin once it is working
#
RUN echo "export ACTS_SPACK_SPEC=\"                                            \
                     acts-core@develop build_type=${ACTS_BUILD_TYPE} -dd4hep   \
                                       +examples +integration_tests +legacy    \
                                       +material_plugin +tests +tgeo           \
                     ^ ${ROOT_SPACK_SPEC}\""                                   \
         >> ${SETUP_ENV}

# Build acts-core, do not install it yet
RUN spack build ${ACTS_SPACK_SPEC}

# Cache the location of the ACTS build directory (it takes a while to compute)
RUN export ACTS_SOURCE_DIR=`spack location --build-dir ${ACTS_SPACK_SPEC}`     \
    && echo "export ACTS_SOURCE_DIR=${ACTS_SOURCE_DIR}" >> ${SETUP_ENV}        \
    && echo "export ACTS_BUILD_DIR=${ACTS_SOURCE_DIR}/spack-build"             \
            >> ${SETUP_ENV}

# Run the unit tests
RUN cd ${ACTS_BUILD_DIR} && spack env acts-core ctest -j8

# Run the integration tests as well
RUN cd ${ACTS_BUILD_DIR}/IntegrationTests                                      \
    && spack env acts-core ./PropagationTests                                  \
    && spack env acts-core ./SeedingTest

# Run the benchmarks as well
RUN cd ${ACTS_BUILD_DIR}/Tests                                                 \
    && spack env acts-core ./Propagator/EigenStepperBenchmark                  \
    && spack env acts-core ./Propagator/AtlasStepperBenchmark                  \
    && spack env acts-core ./Propagator/AtlasPropagatorBenchmark               \
    && spack env acts-core ./Surfaces/BoundaryCheckBenchmark

# Finish installing ACTS
RUN cd ${ACTS_SOURCE_DIR} && spack diy --quiet ${ACTS_SPACK_SPEC}

# Discard the ACTS build directory to keep the Docker image small
RUN spack clean ${ACTS_SPACK_SPEC}

# TODO: Install acts-framework, once it is in a buildable state again
