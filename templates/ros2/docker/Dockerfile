FROM ros:humble-ros-base

ENV ROS_WS_DIR="/ros2_ws"

WORKDIR ${ROS_WS_DIR}

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get -y install \
    git \
    python3-osrf-pycommon \
    python3-vcstool \
 && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=dialog

COPY "/.vscode" "${ROS_WS_DIR}/.vscode"
RUN sed -i -E "s/(ROS_DISTRO=\\$\{1:-\").*(\"\})/\1${ROS_DISTRO}\2/" ${ROS_WS_DIR}/.vscode/ros2_source.bash \
 && echo "alias rsource='source ${ROS_WS_DIR}/.vscode/ros2_source.bash'" >> ~/.bash_aliases \
 && echo "alias rbuild='(cd ${ROS_WS_DIR} && colcon build)'" >> ~/.bash_aliases \
 && echo "source ${ROS_WS_DIR}/.vscode/ros2_source.bash" >> ~/.bashrc
