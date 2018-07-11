FROM ubuntu:14.04

ENV LLVM_VERSION=3.4 \
    CRETE_DEV_PATH=/home/crete/crete-dev \
    CRETE_BUILD_PATH=/home/crete/crete-build \
    UBUNTU_VERSION=14.04.5

RUN apt-get update && \
    apt-get -y --no-install-recommends install \
	build-essential \
	libcap-dev \
	flex \
	bison \
	cmake \
	libelf-dev \
	git \
	libtool \
	libpixman-1-dev \
	minisat \
	zlib1g-dev \
	libglib2.0-dev \
	wget \
	ca-certificates

RUN echo "deb http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.4 main" | sudo tee -a /etc/apt/sources.list
RUN echo "deb-src http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.4 main" | sudo tee -a /etc/apt/sources.list
RUN wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key|sudo apt-key add -

RUN apt-get update && \
    apt-get -y --no-install-recommends install \
	clang-${LLVM_VERSION} \
        llvm-${LLVM_VERSION} \
        llvm-${LLVM_VERSION}-dev \
        llvm-${LLVM_VERSION}-tools

WORKDIR /home
RUN mkdir crete
WORKDIR /home/crete

RUN git clone --recursive https://github.com/justin-bao/crete-dev.git crete-dev

RUN mkdir crete-build
WORKDIR ${CRETE_BUILD_PATH}
RUN CXX=clang++-${LLVM_VERSION} cmake ../crete-dev
RUN make

WORKDIR /home/crete
RUN git clone --recursive https://github.com/justin-bao/test-crete.git crete-run

RUN echo '# Added by CRETE' >> ~/.bashrc
RUN echo export PATH='$PATH':`readlink -f ./bin` >> ~/.bashrc
RUN echo export LD_LIBRARY_PATH='$LD_LIBRARY_PATH':`readlink -f ./bin` >> ~/.bashrc
RUN echo export LD_LIBRARY_PATH='$LD_LIBRARY_PATH':`readlink -f ./bin/boost` >> ~/.bashrc
RUN . ~/.bashrc

WORKDIR /home
