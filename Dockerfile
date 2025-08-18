FROM ubuntu:24.04
# Use the 20.04 LTS release instead of latest to have stable environement

# Create a default Wirepas user
ARG user=wirepas
RUN useradd -ms /bin/bash ${user}

# Install python3, pip and wget
RUN apt-get update \
    && apt-get install -y \
       bzip2 \
       cmake \
       curl \
       libglib2.0-0 \
       ninja-build \
       python3 \
       git \
    && rm -fr /var/libapt/lists/*

WORKDIR /home/${user}

COPY libicu55_55.1-7ubuntu0.5_amd64.deb libicu55_55.1-7ubuntu0.5_amd64.deb
RUN apt install ./libicu55_55.1-7ubuntu0.5_amd64.deb && rm ./libicu55_55.1-7ubuntu0.5_amd64.deb

# Install Arm compiler
RUN curl -Lso my_gcc.tar.gz "https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2" \
    && tar xjf my_gcc.tar.gz -C /opt/ \
    && rm -f my_gcc.tar.gz

# Add Gcc compiler to default path
ENV PATH="/opt/gcc-arm-none-eabi-10.3-2021.10/bin:${PATH}"

# Set the cross-compile prefix for the CMake toolchain
ENV CROSS_COMPILE="arm-none-eabi-"

# Checking GCC ARM installation
RUN echo "GCC ARM Compiler: $(arm-none-eabi-gcc --version | head -1)" >&2 \
    && echo "Location: $(which arm-none-eabi-gcc)" >&2 \
    && echo "CROSS_COMPILE is set to: $CROSS_COMPILE" >&2 \
    && ${CROSS_COMPILE}gcc -dumpversion >&2

RUN apt-get update \
    && apt-get install -y \
       libglib2.0-0 \
    && rm -fr /var/libapt/lists/*

# No need to be root anymore
USER ${user}

# Default to bash console
CMD ["/bin/bash"]
