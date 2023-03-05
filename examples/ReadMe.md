# Examples

Author: [Tobit Flatscher](https://github.com/2b-t) (March 2023)



## Overview

This directory contains several examples of Docker in combination with ROS:

- The ROS Indigo workspace [`affordance_templates_ros_indigo`](./affordance_templates_ros_indigo) shows how Docker can be used to **revive an old ROS workspace** that would require an outdated operating system to run.
- The repository [`docker-realtime`](./docker-realtime) explains how to **set-up a computer with a real-time-patched operating systems** ([`PREEMPT_RT`-patch](https://archive.kernel.org/oldwiki/rt.wiki.kernel.org/index.php/CONFIG_PREEMPT_RT_Patch.html)) and how to run real-time capable code from inside a Docker image.
- The repository [`realsense-ros2-docker`](./realsense-ros2-docker) shows how to use the [**Intel Realsense sensors**](https://www.intelrealsense.com/), such as their depth cameras, from inside a Docker image.
- In the future an example of continuous integration with a Franka Emika Panda in ROS Noetic will be added.
