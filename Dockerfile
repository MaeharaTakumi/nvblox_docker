# syntax=docker/dockerfile:1
# nvblox（Isaac ROS の GPU による 3D 再構成）で地図を作って RViz2 で表示するコンテナ
# Isaac ROS 4.6（Ubuntu 24.04・ROS 2 Jazzy・CUDA 13.2 以上）。RTX 50 系（Blackwell）は Isaac ROS 3.2 が対応しないので 4.x を使う。
# 他のコンテナ（Gazebo 20261002・自己位置推定 test・octomap）は ROS 2 Humble で、DDS で通信する。
# 自分でビルドするコードは無い。設定（launch・パラメータ・RViz）は docker-compose.yml でホストの config/ を割り当てる
#
# ベースは CUDA 13.2 の runtime（ホストのドライバ 595.99 が扱えるのは CUDA 13.2 まで。13.3 以降は動かない）
FROM nvidia/cuda:13.2.1-runtime-ubuntu24.04

ENV TZ=Asia/Tokyo
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

SHELL ["/bin/bash", "-c"]

# ---------- 基本のツールと UTF-8 のロケール ----------
RUN apt-get update && \
    apt-get install -y \
    curl \
    gnupg \
    locales \
    tzdata \
    software-properties-common && \
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    locale-gen en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
    add-apt-repository universe && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ---------- apt リポジトリ ----------
# ROS 2：localization の Dockerfile と同じ手順
# Isaac ROS 4.6：文書の「Configure Isaac ROS Apt Repository」の x86・Option 1（版を固定）
# Jetson（x86_64）：Isaac ROS の依存の VPI（libnvvpi4・vpi4-dev）はここにある。文書の x86 の手順と同じ r39.2
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" > /etc/apt/sources.list.d/ros2.list && \
    curl -fsSL https://isaac.download.nvidia.com/isaac-ros/repos.key | gpg --dearmor -o /usr/share/keyrings/nvidia-isaac-ros.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/nvidia-isaac-ros.gpg] https://isaac.download.nvidia.com/isaac-ros/release-4.6 noble main" > /etc/apt/sources.list.d/nvidia-isaac-ros.list && \
    curl -fsSL https://repo.download.nvidia.com/jetson/jetson-ota-public.asc | gpg --dearmor -o /usr/share/keyrings/nvidia-jetson.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/nvidia-jetson.gpg] https://repo.download.nvidia.com/jetson/x86_64/noble r39.2 main" > /etc/apt/sources.list.d/nvidia-jetson-apt-source.list

# ---------- ROS 2 Jazzy・nvblox・RViz2 ----------
# ベースのイメージは libcublas-13-2 を固定（apt-mark hold）しているが、Isaac ROS が引き込む cuda-libraries-13-2 が
# それより新しい版を求めるので、固定を外す
RUN apt-mark unhold libcublas-13-2 && \
    apt-get update && \
    apt-get install -y \
    ros-jazzy-ros-base \
    ros-jazzy-rviz2 \
    ros-jazzy-isaac-ros-nvblox \
    mesa-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ---------- bashrc（localization の Dockerfile と同じ形を Jazzy に直したもの。ros2_ws は無いので install/setup.bash は読まない） ----------
RUN cat >> ~/.bashrc <<'EOF'
source /opt/ros/jazzy/setup.bash
export ROS_DOMAIN_ID=11

# 通信設定。使う方だけを有効にし、新しい端末を開く（既存の端末には反映されない）
# Jazzy では ROS_LOCALHOST_ONLY は非推奨（ROS_AUTOMATIC_DISCOVERY_RANGE に置き換わった）なので使わない
# --- 実機（LiDAR PC と LAN 越しに通信する） ---
# export FASTDDS_BUILTIN_TRANSPORTS=UDPv4
# unset RMW_IMPLEMENTATION FASTRTPS_DEFAULT_PROFILES_FILE ROS_AUTOMATIC_DISCOVERY_RANGE
# --- Gazebo（同じ PC 内だけで通信し、LAN には出ない） ---
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
export FASTRTPS_DEFAULT_PROFILES_FILE=/root/fastdds_localhost.xml
# 探索の範囲は fastdds_localhost.xml で 127.0.0.1 に限る。LOCALHOST にすると rmw が通信の方式を変えるので SUBNET（既定）のままにする
export ROS_AUTOMATIC_DISCOVERY_RANGE=SUBNET
unset FASTDDS_BUILTIN_TRANSPORTS ROS_LOCALHOST_ONLY
EOF

COPY src/aliases.txt /root/.bash_aliases
COPY src/fastdds_localhost.xml /root/fastdds_localhost.xml
# この README（コマンドの一覧など）をコンテナの中でも読めるようにする
COPY README.md /root/nvblox/README.md
