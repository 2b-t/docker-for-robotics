FROM osrf/ros:indigo-desktop-full

ENV ROS_WS_DIR="/affordance_templates_ws"
WORKDIR ${ROS_WS_DIR}

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get -y install \
    git \
    libboost-dev \
    libdw-dev \
    libqt5svg5-dev \
    libzmq3-dev \
    python-catkin-tools \
    qtbase5-dev \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
 && apt-get -y install \
    ros-${ROS_DISTRO}-control* \
    ros-${ROS_DISTRO}-gazebo-plugins \
    ros-${ROS_DISTRO}-gazebo-ros-control* \
    ros-${ROS_DISTRO}-moveit* \
    ros-${ROS_DISTRO}-navigation \
    ros-${ROS_DISTRO}-object-recognition-ros \
    ros-${ROS_DISTRO}-octomap-rviz-plugins \
    ros-${ROS_DISTRO}-orocos-kdl \
    ros-${ROS_DISTRO}-ros-control* \
    ros-${ROS_DISTRO}-rqt \
    ros-${ROS_DISTRO}-simulators \
    ros-${ROS_DISTRO}-trac-ik* \
 && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=dialog

