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
COPY --chmod=0755 ./start_isaac.sh /usr/local/share/isaac-sim-tools/start_isaac.sh
COPY --chmod=0755 ./isaac_cuda_env.sh /usr/local/share/isaac-sim-tools/isaac_cuda_env.sh
RUN cat << 'EOF' > /usr/local/bin/start-isaac && chmod +x /usr/local/bin/start-isaac
#!/usr/bin/env bash
script=/root/work/src/docker/start_isaac.sh
if [[ ! -x "${script}" ]]; then
  script=/usr/local/share/isaac-sim-tools/start_isaac.sh
fi
exec "${script}" "$@"
EOF

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

# xacro 展開（convert_xacro_to_usd.sh 使用 python3，不需啟動 Isaac Sim）
RUN apt update \
 && apt install -y --no-install-recommends \
    python3-pip \
 && python3 -m pip install --no-cache-dir --break-system-packages xacro \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

############################### ISAAC LAB #####################################
# Isaac Lab v2.3.x 對應 Isaac Sim 5.1；安裝流程參考官方 docker/Dockerfile.base
SHELL ["/bin/bash", "-c"]
ARG ISAAC_LAB_VERSION=v2.3.2
ENV ISAACSIM_ROOT_PATH=/isaac-sim
ENV ISAACLAB_PATH=/root/work/IsaacLab
ENV TERM=xterm

RUN apt update \
 && apt install -y --no-install-recommends \
    build-essential \
    cmake \
    libglib2.0-0 \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${ISAAC_LAB_VERSION}" \
    https://github.com/isaac-sim/IsaacLab.git "${ISAACLAB_PATH}" \
 && chmod +x "${ISAACLAB_PATH}/isaaclab.sh" \
 && ln -sf "${ISAACSIM_ROOT_PATH}" "${ISAACLAB_PATH}/_isaac_sim"

RUN "${ISAACSIM_ROOT_PATH}/python.sh" -m pip install toml

RUN "${ISAACSIM_ROOT_PATH}/python.sh" "${ISAACLAB_PATH}/tools/install_deps.py" apt "${ISAACLAB_PATH}/source" \
 && apt -y autoremove \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# flatdict 在 pip build isolation 下會因缺少 pkg_resources 失敗，需先預裝
RUN "${ISAACSIM_ROOT_PATH}/python.sh" -m pip install --no-build-isolation flatdict==4.0.1

RUN TERM=xterm "${ISAACLAB_PATH}/isaaclab.sh" --install \
 && "${ISAACSIM_ROOT_PATH}/python.sh" -m pip uninstall -y quadprog

# HuggingFace CLI (for downloading motion CSVs from HF datasets)
# Install into Isaac Lab's python env so it works with `./isaaclab.sh -p ...`
RUN "${ISAACLAB_PATH}/_isaac_sim/python.sh" -m pip install --no-cache-dir -U huggingface_hub
RUN "${ISAACLAB_PATH}/_isaac_sim/python.sh" -m pip install --no-cache-dir -U wandb
RUN cat <<'EOF' > /usr/local/bin/huggingface-cli && chmod +x /usr/local/bin/huggingface-cli
#!/usr/bin/env bash
set -euo pipefail
exec /root/work/IsaacLab/_isaac_sim/python.sh -m huggingface_hub.cli.hf "$@"
EOF

# torch 2.7+cu128 expects CUDA 12 libs under site-packages/nvidia/{cublas,cuda_runtime,...}
RUN ISAAC="${ISAACSIM_ROOT_PATH}" && \
    SITE="${ISAAC}/kit/python/lib/python3.11/site-packages/nvidia" && \
    ML="${ISAAC}/exts/omni.isaac.ml_archive/pip_prebundle/nvidia" && \
    mkdir -p "${SITE}" && \
    for pkg in "${ML}"/*; do \
      name="$(basename "${pkg}")"; \
      [ "${name}" = "__init__.py" ] && continue; \
      [ -d "${pkg}" ] || continue; \
      [ -e "${SITE}/${name}" ] || ln -sfn "${pkg}" "${SITE}/${name}"; \
    done

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
      command = /root/work/src/docker/start_isaac.sh
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

alias start-isaac="/root/work/src/docker/start_isaac.sh"
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# --- Isaac Sim CUDA libs (torch 2.7.x after Isaac Lab install) ---
if [[ -f /root/work/src/docker/isaac_cuda_env.sh ]]; then
  source /root/work/src/docker/isaac_cuda_env.sh
fi

# --- Isaac Lab ---
export ISAACSIM_PATH=/isaac-sim
export ISAACSIM_PYTHON_EXE=/isaac-sim/python.sh
export ISAACLAB_PATH=/root/work/IsaacLab
alias isaaclab="\${ISAACLAB_PATH}/isaaclab.sh"
alias python="\${ISAACLAB_PATH}/_isaac_sim/python.sh"
alias python3="\${ISAACLAB_PATH}/_isaac_sim/python.sh"
alias pip="\${ISAACLAB_PATH}/_isaac_sim/python.sh -m pip"
alias pip3="\${ISAACLAB_PATH}/_isaac_sim/python.sh -m pip"
EOF

WORKDIR /root/work

ENTRYPOINT [ "/entrypoint.sh", "terminator" ]
