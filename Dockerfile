FROM ubuntu:22.04 as builder

RUN apt-get update -y &&\
    apt-get install --no-install-recommends -y \
    build-essential\
    wget\
    locales\
    zlib1g-dev\
    ca-certificates\
    libbz2-dev\
    liblzma-dev\
    libdeflate-dev\
    autoconf\
    libcurl4-openssl-dev\
    libcrypto++-dev\
    libncurses-dev\
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

ENV OPT /opt/hie
ENV PATH $OPT/bin:$PATH
ENV LD_LIBRARY_PATH $OPT/lib
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# build tools from other repos
ADD build/opt-build.sh build/
RUN bash build/opt-build.sh $OPT

# build the tools in this repo, separate to reduce build time on errors
COPY . .

FROM ubuntu:22.04

RUN apt-get -yq update &&\
    apt-get install -yq --no-install-recommends &&\
    apt-get update -y &&\
    apt-get install --no-install-recommends -y \
    locales \
    curl \
    bzip2 \
    zlib1g\
    ca-certificates\
    liblzma5\
    libdeflate0\
    autoconf\
    libcrypto++\
    libncurses5 &&\
    apt-get remove -yq unattended-upgrades && \
    apt-get autoremove -yq &&\
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

ENV HIE_OPT /opt/hie
ENV PATH $HIE_OPT/bin:$PATH
ENV LD_LIBRARY_PATH $HIE_OPT/lib
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

RUN mkdir -p $HIE_OPT
COPY --from=builder $HIE_OPT $HIE_OPT

## USER CONFIGURATION
RUN adduser --disabled-password --gecos '' ubuntu && chsh -s /bin/bash && mkdir -p /home/ubuntu

USER    ubuntu
WORKDIR /home/ubuntu

CMD ["/bin/bash"]
