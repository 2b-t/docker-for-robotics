##############
# Base image #
##############
FROM ros:noetic-robot as base

ARG CATKIN_WORKSPACE_DIR="/catkin_ws"

LABEL org.opencontainers.image.authors="tobit.flatscher@outlook.com"
LABEL description="ROS Noetic Docker template"
LABEL version="1.0"

WORKDIR ${CATKIN_WORKSPACE_DIR}
SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get -y install \
    git \
    python3-catkin-tools \
    python3-osrf-pycommon \
 && rm -rf /var/lib/apt/lists/*

 RUN apt-get update \
 && apt-get -y install \
    ros-${ROS_DISTRO}-compressed-image-transport \
    ros-${ROS_DISTRO}-compressed-depth-image-transport \
    ros-${ROS_DISTRO}-image-transport \
 && rm -rf /var/lib/apt/lists/*

# Add additional installation instructions here...

ENV DEBIAN_FRONTEND=dialog


#####################
# Development image #
#####################
FROM base as dev

ARG CATKIN_WORKSPACE_DIR="/catkin_ws"
ARG USERNAME="developer"
ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y \
    ack \
    bmon \
    cloc \
    gdb \
    htop \
    iperf3 \
    iputils-ping \
    mlocate \
    net-tools \
    psmisc \
    tmux \
    xterm \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
 && apt-get install -y \
    python3-vcstool \
    ros-${ROS_DISTRO}-rqt-common-plugins \
    ros-${ROS_DISTRO}-rqt-robot-plugins \
    ros-${ROS_DISTRO}-rviz \
 && rm -rf /var/lib/apt/lists/*

# Install additional developer tools here...

RUN apt-get update \
 && apt-get install -y sudo \
 && rm -rf /var/lib/apt/lists/* \
 && addgroup --gid ${GID} ${USERNAME} \
 && adduser --disabled-password --gecos '' --uid ${GID} --gid ${GID} ${USERNAME} \
 && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
 && chown -R ${UID}:${GID} /home/${USERNAME} \
 && chown -R ${UID}:${GID} ${CATKIN_WORKSPACE_DIR}
 
ENV DEBIAN_FRONTEND=dialog

RUN echo "alias rsource='source ${CATKIN_WORKSPACE_DIR}/devel/setup.bash'" >> /home/${USERNAME}/.bash_aliases \
 && echo "alias rbuild='(cd ${CATKIN_WORKSPACE_DIR} && catkin build)'" >> /home/${USERNAME}/.bash_aliases \
 && echo "alias rclean='(cd ${CATKIN_WORKSPACE_DIR} && catkin clean -y)'" >> /home/${USERNAME}/.bash_aliases \
 && echo "rsource || source /opt/ros/${ROS_DISTRO}/setup.bash" >> /home/${USERNAME}/.bashrc

USER ${USERNAME}

