FROM ubuntu:18.04

# https://source.android.com/setup/build/initializing
RUN \
  apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    bison \
    build-essential \
    ccache \
    curl \
    flex \
    fontconfig \
    g++-multilib \
    gcc-multilib \
    git \
    gnupg \
    gosu \
    gperf \
    lib32ncurses5-dev \
    lib32z-dev \
    libc6-dev-i386 \
    libgl1-mesa-dev \
    libx11-dev \
    libxml2-utils \
    python \
    python3 \
    sudo \
    unzip \
    x11proto-core-dev \
    xsltproc \
    zip \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

ADD https://storage.googleapis.com/git-repo-downloads/repo /usr/local/bin/
RUN chmod 755 /usr/local/bin/repo

RUN \
  useradd -ms /bin/bash builder \
  && echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER builder
RUN \
  echo '. <(buildenv init)' >> ~/.bashrc \
  && git config --global user.email "builder@aosp" \
  && git config --global user.name "AOSP Builder" \
  && git config --global color.ui auto

USER root
WORKDIR /home/builder

ENV \
  ANDROID_BRANCH="" \
  ANDROID_MIRROR="" \
  ANDROID_TARGET="aosp_arm-eng" \
  REPO_INIT_OPTS="-q" \
  REPO_SYNC_OPTS="-q"

COPY buildenv/entrypoint.sh /buildenv-entrypoint.sh
COPY buildenv/buildenv.sh /usr/local/bin/buildenv

COPY buildenv/buildenv.conf /etc/
COPY buildenv.d/ /etc/buildenv.d/

RUN sed -i 's/^#DOTCMDS=.*/DOTCMDS=setup/' /etc/buildenv.conf

ENTRYPOINT ["/buildenv-entrypoint.sh"]
CMD ["/bin/bash"]
