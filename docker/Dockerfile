FROM ros:noetic-robot

ENV ROS_WS_DIR="/ros_ws"

WORKDIR ${ROS_WS_DIR}

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get -y install \
    git \
    python3-catkin-tools \
    python3-osrf-pycommon \
    python3-vcstool \
 && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=dialog

COPY "/.vscode" "${ROS_WS_DIR}/.vscode"
RUN sed -i -E "s/(ROS_DISTRO=\\$\{1:-\").*(\"\})/\1${ROS_DISTRO}\2/" ${ROS_WS_DIR}/.vscode/ros_source.bash \
 && echo "alias rsource='source ${ROS_WS_DIR}/.vscode/ros_source.bash'" >> ~/.bash_aliases \
 && echo "alias rbuild='(cd ${ROS_WS_DIR} && catkin build)'" >> ~/.bash_aliases \
 && echo "alias rclean='(cd ${ROS_WS_DIR} && catkin clean -y)'" >> ~/.bash_aliases \
 && echo "source ${ROS_WS_DIR}/.vscode/ros_source.bash" >> ~/.bashrc
