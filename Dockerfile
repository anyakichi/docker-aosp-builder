FROM ubuntu:14.04
MAINTAINER INAJIMA Daisuke <inajima@sopht.jp>

RUN \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    bison \
    build-essential \
    ccache \
    curl \
    flex \
    g++-multilib \
    gcc-multilib \
    git-core \
    gnupg \
    gperf \
    lib32ncurses5-dev \
    lib32z-dev \
    libc6-dev-i386 \
    libgl1-mesa-dev \
    libx11-dev \
    libxml2-utils \
    openjdk-7-jdk \
    sudo \
    unzip \
    x11proto-core-dev \
    xsltproc \
    zip \
    zlib1g-dev \
    && \
  rm -rf /var/lib/apt/lists/*

ADD https://storage.googleapis.com/git-repo-downloads/repo /usr/local/bin/
RUN chmod 755 /usr/local/bin/repo

RUN useradd -ms /bin/bash builder
USER builder
RUN \
  echo 'eval $(buildenv init)' >> ~/.bashrc && \
  git config --global user.email "builder@aosp" && \
  git config --global user.name "AOSP Builder" && \
  git config --global color.ui auto

USER root
WORKDIR /home/builder

ENV \
  ANDROID_BRANCH="" \
  ANDROID_MIRROR="" \
  ANDROID_TARGET="" \
  REPO_INIT_OPTS="-q" \
  REPO_SYNC_OPTS="-q"

COPY buildenv/entrypoint.sh /usr/local/sbin/entrypoint
COPY buildenv/buildenv.sh /usr/local/bin/buildenv

COPY build.txt /usr/local/share/buildenv/
COPY extract.txt /usr/local/share/buildenv/

ENTRYPOINT ["/usr/local/sbin/entrypoint"]
CMD ["/bin/bash"]
