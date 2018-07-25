# === DOCKER-SPECIFIC HACKERY ===

FROM hgrasland/root-tests:latest-cxx14
LABEL Description="openSUSE Tumbleweed with ACTS installed" Version="0.1"
CMD bash
ARG ACTS_BUILD_TYPE=RelWithDebInfo


# TODO: Port the rest to Spack

# === SYSTEM SETUP ===

# Install ACTS' extra build prerequisites.
RUN zypper in -y boost-devel cmake libboost_test1_67_0-devel                   \
                 libboost_program_options1_67_0-devel eigen3-devel doxygen     \
                 ninja python2


# === INSTALL ACTS-CORE ===

# Clone the current version of ACTS' core library
RUN git clone https://gitlab.cern.ch/acts/acts-core.git

# Configure the core ACTS build
RUN cd acts-core && mkdir build && cd build                                    \
    && cmake -GNinja -DEIGEN_PREFER_EXPORTED_EIGEN_CMAKE_CONFIGURATION=FALSE   \
             -DACTS_BUILD_EXAMPLES=ON -DACTS_BUILD_INTEGRATION_TESTS=ON        \
             -DACTS_BUILD_MATERIAL_PLUGIN=ON -DACTS_BUILD_TGEO_PLUGIN=ON       \
             -DCMAKE_BUILD_TYPE=$ACTS_BUILD_TYPE ..

# Build the core ACTS library
RUN cd acts-core/build && ninja

# Run the unit tests to check if everything is alright
RUN cd acts-core/build && ctest -j8

# Run integrations tests as well
RUN cd acts-core/build/IntegrationTests                                        \
    && ./PropagationTests                                                      \
    && ./SeedingTest

# Install the core ACTS library
RUN cd acts-core/build && ninja install

# Clean up the ACTS build directory
RUN cd acts-core/build && ninja clean


# === INSTALL ACTS-FRAMEWORK ===

# HACK: This whole section must be disabled for now as the ACTS test framework
#       is not in a buildable state at the moment.
#
# # Clone the current version of ACTS' test framework
# RUN git clone --recursive https://gitlab.cern.ch/acts/acts-framework.git
# 
# # Configure the ACTS test framework build
# RUN cd acts-framework && mkdir build && cd build                               \
#     && cmake -GNinja -DCMAKE_BUILD_TYPE=$ACTS_BUILD_TYPE ..
# 
# # Build and install the ACTS test framework
# RUN cd acts-framework/build && ninja && ninja install
# 
# # TODO: Check if some test framework example runs


# === FINAL CLEAN UP ===

# Discard the system package cache to save up space
RUN zypper clean
