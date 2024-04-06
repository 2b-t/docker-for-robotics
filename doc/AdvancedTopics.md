# Advanced topics

Author: [Tobit Flatscher](https://github.com/2b-t) (2021 - 2023)



## Overview

If you have followed this guide so far, then you should have understood the basics of Docker. There are still some topics I would like to discuss that might be helpful. This section links to the corresponding external documentation or accompanying documents.

## 1. Setting up Visual Studio Code

In the last few years [Microsoft Visual Studio Code has become the most used editor](https://insights.stackoverflow.com/survey/2021), becoming the first Microsoft product to be widely accepted by programmers (which is quite remarkable as they have a history of developing toolchains highly criticized by developers :). The guide [`VisualStudioCodeSetup.md`](./VisualStudioCodeSetup.md) walks you through the set-up of a Docker with Visual Studio Code.

## 2. Graphic user interfaces

As pointed out earlier Docker was never intended for graphic user interfaces and integrating them is slightly tricky as graphic user-interfaces are not part of the kernel but that does not mean that it can't be done. Graphic user interfaces are particularly vital when developing with ROS. The main disadvantage of graphic user interfaces with Docker is though that there is no real portable way of doing so. It highly depends on the operating system that you are using and the manufacturer of your graphics card. The document [`Gui.md`](./Gui.md) discusses a simple way of doing so for Linux operating systems.

## 3. ROS inside Docker

Working with the Robot Operating System (ROS) or its successor ROS 2 might pose particular challenges, such as working with hardware and network discovery of other nodes. I have written down some notes of how I generally structure my Dockers in [`Ros.md`](./Ros.md). In particular this is concerned with working with hardware, multiple machines and time synchronization between them.

## 4. Users and safety

A few problems emerge with user rights and shared volumes when working from a Docker as discussed [in this Stackoverflow post](https://stackoverflow.com/questions/68155641/should-i-run-things-inside-a-docker-container-as-non-root-for-safety) and in more detail [in this blog post](https://jtreminio.com/blog/running-docker-containers-as-current-host-user/). In particular it might be that the container might not be able to write to the shared volume or vice versa the host user can only delete folders created by the Docker user when being a super-user. As outlined in the latter, there are ways to work around this, passing the current user id and group as input arguments to the container. In analogy with Docker-Compose one might default to the root user or change to the current user if [arguments are supplied](https://stackoverflow.com/questions/34322631/how-to-pass-arguments-within-docker-compose).

I personally use Dockers in particular for developing and I am not too bothered about being super-user inside the container. If you are, and depending on your use case you should be (in particular for security reasons), then have a look at the linked posts as well as the [Visual Studio Code guide on this](https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user).

What I generally do is use the **environment variables `${USER}` or `${USERNAME}`**, if provided or else assume reasonable default values, pass them into the container as arguments. Most users will have a user id and a group id corresponding to `1000` as these values are given to the first user account.

```yaml
version: "3.9"
services:
  ros2_docker:
    build:
      context: ..
      dockerfile: docker/Dockerfile
      args:
        - USERNAME=${USERNAME:-developer}
        - UID=1000
        - GID=1000
```

and then create a corresponding user inside the Docker

```dockerfile
RUN apt-get update \
 && apt-get install -y \
    sudo \
 && rm -rf /var/lib/apt/lists/*
RUN addgroup --gid ${GID} ${USERNAME} \
 && adduser --disabled-password --gecos '' --uid ${GID} --gid ${GID} ${USERNAME} \
 && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
 && chown -R ${UID}:${GID} /home/${USERNAME}

USER ${USERNAME}
```

This results in the same user being used inside the Docker than on a Linux-based host system.

You can also put the values for `UID` and `GID` into the environment file so that the user can modify them easily.

## 5. Multi-stage builds

Another interesting topic for **slimming down the resulting containers** as mentioned before are [multi-stage builds](https://docs.docker.com/build/building/multi-stage/) where only the files necessary for running are kept and every unnecessary ballast is removed. It is one of those things that you might have a look at when trying to mastering [Docker best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/).

What I generally use multi-stage builds for is stopping at a specific build stage. Inside my Dockerfile I have a base image for the basic ROS set-up as well as a developer image that adds developer tools on top of it:

```dockerfile
##############
# Base image #
##############
FROM ros:humble-ros-base as base

# Here I install my basic packages, ROS packages and set up the middleware

#####################
# Development image #
#####################
FROM base as dev

# Here I install developer tools for monitoring and visualization as well as create users
```

Then inside my `docker-compose` file I can stop either at the `base` or the `dev` stage as follows:

```yaml
version: "3.9"
services:
  ros2_docker:
    build:
      context: ..
      dockerfile: docker/Dockerfile
      target: dev
```

## 6. Real-time code

As mentioned another point that is often not discussed is what steps are necessary for running real-time code from inside a Docker. As outlined in [this IBM research report](https://domino.research.ibm.com/library/cyberdig.nsf/papers/0929052195DD819C85257D2300681E7B/$File/rc25482.pdf), the impact of Docker on the performance can be very low if launched with the correct options. After all you are using the kernel of the host system and the same scheduler. I have discussed this also in more detail in a [dedicated repository](https://github.com/2b-t/docker-realtime), in particular focussing on `PREEMPT_RT` which is likely the most relevant for robotics.

## 7. Deployment

One might develop inside a container by mounting all necessary directories into the container. For simplicity one might be `root` inside the container. When deploying a container commonly a dedicated release image named e.g. `Dockerfile.release` will be created. This container might use the development image and instead of mounting the corresponding source code into the container the **required dependencies will be installed from Debian packages**. Ideally we have a CI-pipeline that produces these Debian packages (e.g. a Github Action in each repository such as [this](https://github.com/arkane-systems/apt-repo-update)) and another CI-pipeline that pushes the development image to our Docker registry (e.g. for Github Actions see [here](https://docs.github.com/en/actions/publishing-packages/publishing-docker-images)). Both of these can then trigger the generation of the release Dockerfile located in a different repository (e.g. for Github Actions see [here](https://github.com/marketplace/actions/trigger-external-workflow)). Additionally we will use another non-root user inside the Docker.

```dockerfile
# We start from the development image or from the base stage if using multi-stage builds
FROM some_user/some_repo:devel

# We will install now packages as Debians instead of mounting the source code
RUN echo "deb http://packages.awesome-robot.org/robot/ubuntu focal main" > /etc/apt/sources.list.d/awesome-latest.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 00000000000000000000000000000000
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    some-awesome-robot-full=1.0.0 \
 && rm -rf /var/lib/apt/lists/*

# Set-up a new user without password inside the Docker (see also the dedicated section above)
ARG USERNAME=some_user
ARG UID=1000
ARG GID=1000

RUN apt-get update \
 && apt-get install -y \
    sudo \
 && rm -rf /var/lib/apt/lists/*
RUN addgroup --gid ${GID} ${USERNAME} \
 && adduser --disabled-password --gecos '' --uid ${GID} --gid ${GID} ${USERNAME} \
 && chown -R ${UID}:${GID} /home/${USERNAME}

USER ${USERNAME}

# Entrypoint script sources our workspace and launch the main launch file
ENTRYPOINT["entrypoint.sh"]
```

