# Based on top of ubuntu 20.04
# https://github.com/rust-embedded/cross/blob/master/docker/Dockerfile.x86_64-unknown-linux-musl
FROM rustembedded/cross:x86_64-unknown-linux-musl

RUN apt-get update \
    && apt-get -y upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common pkg-config wget musl-tools libc6-dev apt-transport-https ca-certificates \
    && wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
    && add-apt-repository "deb https://apt.llvm.org/focal/ llvm-toolchain-focal-14 main"  \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y llvm-14 clang-14 libclang-14-dev clang-14 make \
    && rm -rf /var/lib/apt/lists/*;

RUN ln -s /usr/include/x86_64-linux-gnu/asm /usr/include/x86_64-linux-musl/asm && \
    ln -s /usr/include/asm-generic /usr/include/x86_64-linux-musl/asm-generic && \
    ln -s /usr/include/linux /usr/include/x86_64-linux-musl/linux && \
    ln -s /usr/bin/g++ /usr/bin/musl-g++

RUN mkdir /musl

# https://www.openssl.org/source/old/1.1.1/
ARG OPENSSL_VERSION=1.1.1p

RUN wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -O - | tar -xz &&\
    cd openssl-${OPENSSL_VERSION} && \
    CC="musl-gcc -fPIE -pie" ./Configure no-shared no-async --prefix=/musl --openssldir=/musl/ssl linux-x86_64 && \
    make depend && \
    make -j $(nproc) && \
    make install_sw && \
    make install_ssldirs && \
    cd .. && rm -rf openssl-${OPENSSL_VERSION}

ENV PKG_CONFIG_ALLOW_CROSS=true
ENV PKG_CONFIG_ALL_STATIC=true
ENV RUSTFLAGS="-C target-feature=-crt-static"

ENV OPENSSL_STATIC=true
ENV OPENSSL_DIR=/musl


ENV PATH="/cargo/bin:$PATH"
