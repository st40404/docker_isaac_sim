FROM nvcr.io/nvidia/isaac-sim:5.1.0

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei

# 關鍵一行：切換成 root
USER root

# 基本工具 + terminator
RUN apt update && apt install -y --no-install-recommends \
    sudo \
    git \
    curl \
    wget \
    htop \
    tmux \
    terminator \
    nano \
    vim \
    fonts-noto-cjk \
    libcanberra-gtk-module \
    libcanberra-gtk3-module \
    gir1.2-keybinder-3.0 \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace