# Isaac Sim 5.1 的 RTX 堆疊在驅動 595.x + Blackwell（RTX PRO 6000）會在
# librtx.scenedb 啟動時 segfault。6.2.0 是 Isaac Lab 3.0.0 對應的映像，可留在 595.84。
FROM ghcr.io/astral-sh/uv:0.12.9@sha256:8b940d3a9d65bed080436972241af2e21c84b5e8c9193f7014ed71479ee795ff AS uv

FROM nvcr.io/nvidia/isaac-sim:6.2.0

############################## SYSTEM PARAMETERS ##############################
ARG ENTRYPOINT_FILE=entrypoint.sh

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

# WandB defaults for BeyondMimic (csv_to_npz / train / replay)
ENV WANDB_MODE=online
ENV WANDB_ENTITY=lung40404-graphen

USER root

# 部分 Isaac Sim pip_prebundle 把 idna 做成斷掉的符號連結。
# 只修實際壞掉的套件；6.2 若已修好則略過，避免寫死 5.1 的 cp311 路徑。
RUN set -eu \
 && find /isaac-sim -path '*/idna/__init__.py' -xtype l -print > /tmp/idna-broken.txt 2>/dev/null || true \
 && if [ ! -s /tmp/idna-broken.txt ]; then \
      echo "idna: no broken symlinks"; \
    else \
      /isaac-sim/python.sh -m pip install --no-cache-dir --target /tmp/idna-pkg 'idna==3.10'; \
      while IFS= read -r init; do \
        dir="$(dirname "${init}")"; \
        rm -rf "${dir}"; \
        cp -a /tmp/idna-pkg/idna "${dir}"; \
        test -f "${dir}/__init__.py"; \
        test ! -L "${dir}/__init__.py"; \
        test -f "${dir}/core.py"; \
        echo "idna repaired: ${dir}"; \
      done < /tmp/idna-broken.txt; \
      rm -rf /tmp/idna-pkg; \
    fi \
 && rm -f /tmp/idna-broken.txt

# 台灣 apt 鏡像
RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list || true

# 時區
RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime \
 && echo "${TZ}" > /etc/timezone

COPY --from=uv /uv /uvx /usr/local/bin/

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
    git-lfs \
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
 && git lfs install \
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
# Isaac Lab v3.0.0 對應 Isaac Sim 6.2。依賴裝進 Kit Python 上的 uv venv，
# 與官方 docker/Dockerfile.base 相同，避免 pip_prebundle 的 torch 蓋掉 venv。
SHELL ["/bin/bash", "-c"]
ARG ISAAC_LAB_VERSION=v3.0.0
ENV ISAACSIM_ROOT_PATH=/isaac-sim
ENV ISAACLAB_PATH=/root/work/IsaacLab
ENV TERM=xterm
ENV VIRTUAL_ENV=/opt/isaaclab-venv
ENV UV_PROJECT_ENVIRONMENT=/opt/isaaclab-venv
ENV UV_PYTHON=/isaac-sim/kit/python/bin/python3
ENV UV_PYTHON_PREFERENCE=only-system
ENV UV_HTTP_RETRIES=12
ENV MUJOCO_GL=disable
ENV HUB__ARGS__DETECT_ONLY=false

RUN apt update \
 && apt install -y --no-install-recommends \
    build-essential \
    cmake \
    libglib2.0-0 \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${ISAAC_LAB_VERSION}" \
    https://github.com/isaac-sim/IsaacLab.git "${ISAACLAB_PATH}" \
 && find "${ISAACLAB_PATH}" -type f -name "*.sh" -exec sed -i 's/\r$//' {} + \
 && chmod 755 "${ISAACLAB_PATH}/isaaclab.sh" \
 && ln -sfn "${ISAACSIM_ROOT_PATH}" "${ISAACLAB_PATH}/_isaac_sim" \
 && bash "${ISAACLAB_PATH}/docker/scripts/install_carb_env_shim.sh" "${ISAACSIM_ROOT_PATH}" \
 && mkdir -p /var/cache/hub

RUN test -x "${UV_PYTHON}" \
 && uv venv --seed "${VIRTUAL_ENV}"

# 第三方依賴先裝；workspace 套件稍後再裝，讓 install_deps.py 能從原始碼 import isaaclab。
ARG ISAACLAB_EXTRAS="--extra rsl-rl"
RUN cd "${ISAACLAB_PATH}" \
 && uv sync --frozen --inexact ${ISAACLAB_EXTRAS} \
      --no-install-workspace --no-install-package imageio-ffmpeg

RUN "${ISAACLAB_PATH}/isaaclab.sh" -p "${ISAACLAB_PATH}/tools/install_deps.py" apt "${ISAACLAB_PATH}/source" \
 && apt -y autoremove \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN cd "${ISAACLAB_PATH}" \
 && uv sync --frozen --inexact ${ISAACLAB_EXTRAS} \
      --no-install-package imageio-ffmpeg

# runheadless.sh 會先吃到 pip_prebundle 的 torch；改指向 venv，避免 CUDA/NCCL 符號不符。
RUN "${ISAACLAB_PATH}/isaaclab.sh" -p -c \
    "from isaaclab.cli.commands.install import _repoint_prebundle_packages; _repoint_prebundle_packages()"

ENV UV_PYTHON=/opt/isaaclab-venv/bin/python

# HuggingFace CLI / WandB / TensorBoard 裝進 venv，讓 isaaclab.sh -p 看得到。
RUN uv pip install --no-cache-dir huggingface_hub wandb tensorboard
RUN cat <<'EOF' > /usr/local/bin/huggingface-cli && chmod +x /usr/local/bin/huggingface-cli
#!/usr/bin/env bash
set -euo pipefail
exec /opt/isaaclab-venv/bin/python -m huggingface_hub.cli.hf "$@"
EOF
RUN cat <<'EOF' > /usr/local/bin/tensorboard && chmod +x /usr/local/bin/tensorboard
#!/usr/bin/env bash
set -euo pipefail
exec /opt/isaaclab-venv/bin/python -m tensorboard.main "$@"
EOF

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

# --- Isaac Sim / Lab runtime（6.2 的 carb shim 在 /etc/ld.so.preload）---
if [[ -f /root/work/src/docker/isaac_cuda_env.sh ]]; then
  source /root/work/src/docker/isaac_cuda_env.sh
fi

# --- Isaac Lab 3.0：python / pip 走 venv，isaaclab.sh -p 才載得到 Kit ---
export ISAACSIM_PATH=/isaac-sim
export ISAACSIM_PYTHON_EXE=/isaac-sim/python.sh
export ISAACLAB_PATH=/root/work/IsaacLab
export VIRTUAL_ENV=/opt/isaaclab-venv
export PATH="/opt/isaaclab-venv/bin:$PATH"
alias isaaclab="\${ISAACLAB_PATH}/isaaclab.sh"
alias python="\${ISAACLAB_PATH}/isaaclab.sh -p"
alias python3="\${ISAACLAB_PATH}/isaaclab.sh -p"
alias pip="uv pip"
alias pip3="uv pip"
EOF

WORKDIR /root/work

ENTRYPOINT [ "/entrypoint.sh", "bash" ]
