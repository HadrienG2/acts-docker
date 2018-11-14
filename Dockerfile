# Configure the container's basic properties
FROM hgrasland/root-tests:latest-cxx14
LABEL Description="openSUSE Tumbleweed with ACTS installed" Version="0.1"
CMD bash
ARG ACTS_BUILD_TYPE=RelWithDebInfo

# Switch to a development branch of Spack with an updated ACTS package
#
# FIXME: Move back to official Spack repo once the ACTS package is upstreamed.
#
RUN cd /opt/spack                                                              \
    && git fetch HadrienG2                                                     \
    && git checkout HadrienG2/acts-package

# This is the variant of the ACTS package which we are going to build
RUN echo "export ACTS_SPACK_SPEC=\"                                            \
                     acts-core@develop build_type=${ACTS_BUILD_TYPE} +dd4hep   \
                                       +digitization +examples                 \
                                       +integration_tests +json +legacy        \
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
RUN cd ${ACTS_BUILD_DIR}/Tests/Integration                                     \
    && spack env acts-core ./PropagationTests                                  \
    && spack env acts-core ./SeedingTest

# Run the benchmarks as well
RUN cd ${ACTS_BUILD_DIR}/Tests/Core                                            \
    && spack env acts-core ./Propagator/EigenStepperBenchmark                  \
    && spack env acts-core ./Propagator/AtlasStepperBenchmark                  \
    && spack env acts-core ./Propagator/AtlasPropagatorBenchmark               \
    && spack env acts-core ./Surfaces/BoundaryCheckBenchmark

# Finish installing ACTS
RUN cd ${ACTS_SOURCE_DIR} && spack diy --quiet ${ACTS_SPACK_SPEC}

# Discard the ACTS build directory and the associated environment setup
RUN spack clean ${ACTS_SPACK_SPEC}                                             \
    && mv ${SETUP_ENV} ${SETUP_ENV}.old                                        \
    && grep -E --invert-match "ACTS_(SOURCE|BUILD)_DIR" ${SETUP_ENV}.old       \
            >> ${SETUP_ENV}                                                    \
    && rm ${SETUP_ENV}.old

# TODO: Install acts-framework, once it is in a buildable state again
