FROM nvcr.io/nvidia/isaac-sim:5.1.0

############################## SYSTEM PARAMETERS ##############################
ARG ENTRYPOINT_FILE=entrypoint.sh

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

USER root

# 台灣 apt 鏡像
RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list || true

# 時區
RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime \
 && echo "${TZ}" > /etc/timezone

COPY --chmod=0755 ./${ENTRYPOINT_FILE} /entrypoint.sh

############################### INSTALL #######################################
RUN apt update \
 && apt install -y --no-install-recommends \
    sudo \
    git \
    htop \
    wget \
    curl \
    psmisc \
    tmux \
    terminator \
    nano \
    vim \
    gnome-terminal \
    libcanberra-gtk-module \
    libcanberra-gtk3-module \
    gir1.2-keybinder-3.0 \
    bash-completion \
    iputils-ping \
    net-tools \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# 中文字型
RUN apt update \
 && apt install -y --no-install-recommends \
    fonts-noto-cjk \
 && fc-cache -fv \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

############################## USER CONFIG ####################################
WORKDIR /root

# Terminator 設定（與 ROS 範例相同格式）
RUN mkdir -p /root/.config/terminator && \
    cat << 'EOF' > /root/.config/terminator/config
[global_config]
[keybindings]
[profiles]
  [[default]]
    cursor_color = "#aaaaaa"
    font = Monospace 16
    use_system_font = False
    use_theme = True
    login_shell = True
[layouts]
  [[default]]
    [[[window0]]]
      type = Window
      parent = ""
    [[[child1]]]
      type = Terminal
      parent = window0
  [[isaac_sim]]
    [[[window0]]]
      type = Window
      parent = ""
    [[[child1]]]
      type = VPaned
      parent = window0
      ratio = 0.72
    [[[child2]]]
      type = Terminal
      parent = child1
      command = /entrypoint.sh isaac
      profile = default
    [[[child3]]]
      type = Terminal
      parent = child1
      command = bash -l
      profile = default
[plugins]
EOF

# Bash 彩色提示字與常用設定
RUN cat << 'EOF' >> /root/.bashrc

# --- colored prompt ---
export TERM=xterm-256color
export CLICOLOR=1
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

color_prompt=yes
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w# '
fi
unset color_prompt

if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

alias start-isaac="/entrypoint.sh isaac"
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
EOF

WORKDIR /root/work

ENTRYPOINT [ "/entrypoint.sh", "terminator" ]
