# Examples

Author: [Tobit Flatscher](https://github.com/2b-t) (March - May 2023)



## Overview

This directory contains several examples of Docker in combination with ROS:

- The ROS Indigo workspace [`affordance-templates-ros-docker`](./affordance-templates-ros-docker) shows how Docker can be used to **revive an old ROS workspace** that would require an outdated operating system to run.
- The repository [`docker-realtime`](./docker-realtime) explains how to **set-up a computer with a real-time-patched operating systems** ([`PREEMPT_RT`-patch](https://archive.kernel.org/oldwiki/rt.wiki.kernel.org/index.php/CONFIG_PREEMPT_RT_Patch.html)) and how to run real-time capable code from inside a Docker container.
- The workspace [`lpms-ros-docker`](./lpms-ros-docker) and the repository [`realsense-ros2-docker`](./realsense-ros2-docker) show how to give access to **external hardware connected via USB** to a Docker with examples for a [**Life Performance Research IMU**](https://www.lp-research.com/) as well as [**Intel Realsense sensors**](https://www.intelrealsense.com/), such as their depth cameras.
- The repository [`velodyne-ros2-docker`](./velodyne-ros2-docker) shows how to give access to **devices connected over Ethernet** to a Docker using the example of a [**Velodyne 3D lidar**](https://velodynelidar.com/).
