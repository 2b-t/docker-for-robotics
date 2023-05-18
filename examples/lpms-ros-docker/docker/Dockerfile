FROM ros:noetic-robot

ENV WS_DIR="/lpms_ws"
WORKDIR ${WS_DIR}

SHELL ["/bin/bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y \
    build-essential \
    cmake \
    git-all \
    software-properties-common \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
 && apt-get install -y \
    ros-${ROS_DISTRO}-openzen-sensor \
    ros-${ROS_DISTRO}-rviz \
    ros-${ROS_DISTRO}-rviz-imu-plugin \
    ros-${ROS_DISTRO}-rviz-plugin-tutorials \
 && rm -rf /var/lib/apt/lists/*

ARG DEBIAN_FRONTEND=dialog
