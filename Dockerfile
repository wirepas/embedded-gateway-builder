FROM ubuntu:22.04
# Builder of the Quectel EC800U (UniRTOS, uis8852) OpenCPU image on Linux.
# The SDK build itself uses the RISC-V compiler shipped in the SDK (prebuilts/linux/...), so the SDK checkout is mounted
# and the build runs inside. This image holds the host tools the SDK build needs, and a RISC-V GCC in the PATH to build
# the libraries linked into the application (the meter library) outside of the SDK.

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

# RISC-V GCC 13.1.1 (newlib) of Nuclei: the very build shipped in the SDK (same build.txt, 2024-02-18, pipeline 161339,
# GCC b12706a39), with the multilib of the EC800U (rv32ima_zca_zcb_zcmp_zcmt_zba_zbb_zbc_zbs, ilp32).
ARG RISCV_GCC_VERSION=nuclei-2024
ARG RISCV_GCC_ARCHIVE=nuclei_riscv_newlibc_prebuilt_linux64_${RISCV_GCC_VERSION}.tar.bz2
ARG RISCV_GCC_URL=https://download.nucleisys.com/upload/files/toolchain/gcc/${RISCV_GCC_ARCHIVE}
ARG RISCV_GCC_SHA256=43d69169d8d3267c37549fb2a7212ac7666e5ba31f175beea1991b0601cffd84
ARG RISCV_GCC_ROOT=/opt/riscv-gcc
RUN wget -q --tries=3 --timeout=120 -O "/tmp/${RISCV_GCC_ARCHIVE}" "${RISCV_GCC_URL}" \
    && echo "${RISCV_GCC_SHA256}  /tmp/${RISCV_GCC_ARCHIVE}" | sha256sum -c - \
    && mkdir -p "${RISCV_GCC_ROOT}" \
    && tar -xjf "/tmp/${RISCV_GCC_ARCHIVE}" -C "${RISCV_GCC_ROOT}" --strip-components=1 \
    && rm -f "/tmp/${RISCV_GCC_ARCHIVE}" \
    && "${RISCV_GCC_ROOT}/bin/riscv64-unknown-elf-gcc" --version

ENV UNIRTOS_GCC_TOOLCHAIN_PATH=${TOOLCHAIN_ROOT}/gcc/${ARM_GCC_VERSION}
ENV UNIRTOS_TOOLCHAIN_PATH=${UNIRTOS_GCC_TOOLCHAIN_PATH}
ENV UNIRTOS_TOOLCHAIN_PATH_WIN=${UNIRTOS_GCC_TOOLCHAIN_PATH}
ENV PATH=${UNIRTOS_GCC_TOOLCHAIN_PATH}/bin:${RISCV_GCC_ROOT}/bin:${PATH}
ENV CMAKE_SYSTEM_NAME=Generic

WORKDIR /home/${user}

# No need to be root anymore
USER ${user}

# Default to bash console
CMD ["/bin/bash"]
