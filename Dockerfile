FROM nvcr.io/nvidia/isaac-sim:5.1.0

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

USER root

RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list || true \
 && ln -snf /usr/share/zoneinfo/Asia/Taipei /etc/localtime \
 && echo Asia/Taipei > /etc/timezone

RUN apt update && apt install -y --no-install-recommends \
    sudo \
    git \
    curl \
    wget \
    htop \
    tmux \
    nano \
    vim \
    terminator \
    fonts-noto-cjk \
    libcanberra-gtk-module \
    libcanberra-gtk3-module \
    gir1.2-keybinder-3.0 \
    bash-completion \
    iputils-ping \
    net-tools \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 entrypoint.sh /entrypoint.sh
COPY config/terminator/config /root/.config/terminator/config

WORKDIR /root/work

ENTRYPOINT ["/entrypoint.sh"]
CMD ["terminator"]
