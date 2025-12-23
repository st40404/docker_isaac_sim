FROM nvcr.io/nvidia/isaac-sim:5.1.0

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei

#### 需要安裝套件時才要開啟
# # 切換成 root 來使用 apt
# USER root

# # 安裝基本工具
# RUN apt update && apt install -y --no-install-recommends \
#     sudo \
#     git \
#     curl \
#     wget \
#     htop \
#     tmux \
#     nano \
#     vim \
#     fonts-noto-cjk \
#     libcanberra-gtk-module \
#     libcanberra-gtk3-module \
#     gir1.2-keybinder-3.0 \
#  && apt clean \
#  && rm -rf /var/lib/apt/lists/*

# WORKDIR /root
WORKDIR /root/work