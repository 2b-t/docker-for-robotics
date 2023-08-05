##############
# Base image #
##############
FROM ros:humble-ros-base as base

ENV ROS_WS_DIR="/ament_ws"
WORKDIR ${ROS_WS_DIR}

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get -y install \
    git \
    python3-colcon-clean \
    python3-osrf-pycommon \
 && rm -rf /var/lib/apt/lists/*

# Add additional installation instructions here...

ENV DEBIAN_FRONTEND=dialog


#####################
# Development image #
#####################
FROM base as dev

ARG USERNAME=${USERNAME}
ARG UID=${UID}
ARG GID=${GID}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y \
    iputils-ping \
    net-tools \
    python3-vcstool \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
 && apt-get install -y \
    ros-${ROS_DISTRO}-rviz2 \
 && rm -rf /var/lib/apt/lists/*

# Install additional developer tools here...

ENV DEBIAN_FRONTEND=dialog

RUN addgroup --gid ${GID} ${USERNAME} \
 && adduser --disabled-password --gecos '' --uid ${GID} --gid ${GID} ${USERNAME} \
 && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
 && chown -R ${UID}:${GID} /home/${USERNAME} \
 && chown -R ${UID}:${GID} ${ROS_WS_DIR}

COPY "/.vscode" "${ROS_WS_DIR}/.vscode"
RUN sed -i -E "s/(ROS_DISTRO=\\$\{1:-\").*(\"\})/\1${ROS_DISTRO}\2/" ${ROS_WS_DIR}/.vscode/ros2_source.bash \
 && echo "alias rsource='source ${ROS_WS_DIR}/.vscode/ros2_source.bash'" >> /home/${USERNAME}/.bash_aliases \
 && echo "alias rbuild='(cd ${ROS_WS_DIR} && colcon build)'" >> /home/${USERNAME}/.bash_aliases \
 && echo "alias rclean='(cd ${ROS_WS_DIR} && colcon clean workspace -y)'" >> /home/${USERNAME}/.bash_aliases \
 && echo "source ${ROS_WS_DIR}/.vscode/ros2_source.bash" >> /home/${USERNAME}/.bashrc

USER ${USERNAME}

