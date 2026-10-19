FROM ubuntu:22.04
# Builder of the Quectel EC800U (UniRTOS, uis8852) OpenCPU image on Linux.
# The RISC-V compiler is NOT in this image: it ships in the SDK (prebuilts/linux/...), so the SDK checkout is mounted
# and the build runs inside. This image only holds the host tools the SDK build needs.

# Create a default Wirepas user
ARG user=wirepas
RUN useradd -ms /bin/bash ${user}

ENV DEBIAN_FRONTEND=noninteractive

# The i386 libs are for the SDK's bundled nanopb protoc, which is a 32-bit binary even in the x86_64 prebuilts.
RUN dpkg --add-architecture i386 \
    && apt-get update -qq && apt-get install -y --no-install-recommends \
        build-essential \
        bzip2 \
        ca-certificates \
        cmake \
        file \
        git \
        libc6:i386 \
        libglib2.0-0 \
        libstdc++6:i386 \
        ninja-build \
        p7zip-full \
        python-is-python3 \
        python3 \
        tar \
        unzip \
        wget \
        zlib1g:i386 \
    && rm -rf /var/lib/apt/lists/* \
    && git config --system --add safe.directory '*'

# ARM GCC, laid out the way the SDK's buildlib.sh auto-detects it (UNIRTOS_GCC_TOOLCHAIN_PATH + a
# gcc-arm-none-eabi-10.2.1 symlink)
ARG ARM_GCC_VERSION=gcc-arm-none-eabi-10-2020-q4-major
ARG ARM_GCC_ARCHIVE=${ARM_GCC_VERSION}-x86_64-linux.tar.bz2
ARG ARM_GCC_URL=https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/${ARM_GCC_ARCHIVE}
ARG TOOLCHAIN_ROOT=/opt/unirtos-toolchain
RUN mkdir -p "${TOOLCHAIN_ROOT}/gcc" \
    && wget -q --tries=3 --timeout=60 -O "/tmp/${ARM_GCC_ARCHIVE}" "${ARM_GCC_URL}" \
    && tar -xjf "/tmp/${ARM_GCC_ARCHIVE}" -C "${TOOLCHAIN_ROOT}/gcc" \
    && rm -f "/tmp/${ARM_GCC_ARCHIVE}" \
    && ln -sfn "${TOOLCHAIN_ROOT}/gcc/${ARM_GCC_VERSION}" "${TOOLCHAIN_ROOT}/gcc-arm-none-eabi-10.2.1"

ENV UNIRTOS_GCC_TOOLCHAIN_PATH=${TOOLCHAIN_ROOT}/gcc/${ARM_GCC_VERSION}
ENV UNIRTOS_TOOLCHAIN_PATH=${UNIRTOS_GCC_TOOLCHAIN_PATH}
ENV UNIRTOS_TOOLCHAIN_PATH_WIN=${UNIRTOS_GCC_TOOLCHAIN_PATH}
ENV PATH=${UNIRTOS_GCC_TOOLCHAIN_PATH}/bin:${PATH}
ENV CMAKE_SYSTEM_NAME=Generic

WORKDIR /home/${user}

# No need to be root anymore
USER ${user}

# Default to bash console
CMD ["/bin/bash"]
