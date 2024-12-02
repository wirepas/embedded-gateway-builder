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
RUN curl -Lso gcc-arm-none-eabi-7-2017-q4-major-linux.tar.bz2 "https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/7-2017q4/gcc-arm-none-eabi-7-2017-q4-major-linux.tar.bz2" \
    && tar xjf gcc-arm-none-eabi-7-2017-q4-major-linux.tar.bz2 -C /opt/ \
    && rm -f gcc-arm-none-eabi-7-2017-q4-major-linux.tar.bz2

# Add Gcc 7 compiler to default path
ENV PATH="/opt/gcc-arm-none-eabi-7-2017-q4-major/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y \
       libglib2.0-0 \
    && rm -fr /var/libapt/lists/*

# No need to be root anymore
USER ${user}

# Default to bash console
CMD ["/bin/bash"]
