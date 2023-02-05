# Docker for Robotics with the Robot Operating System (ROS/ROS2)

Author: [Tobit Flatscher](https://github.com/2b-t) (August 2021 - February 2023)

[![Tests](https://github.com/2b-t/docker-for-ros/actions/workflows/build.yml/badge.svg)](https://github.com/2b-t/docker-for-ros/actions/workflows/build.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)



## Overview

This guide discusses best practices for **robotics development with the [Robot Operating System (ROS/ROS2)](https://www.ros.org/) and Docker/Docker-Compose**. This includes displaying **graphic user interfaces**, working with hardware, **real-time capable code** and the **network set-up** for multiple machines. Additionally it walks you through the **set-up with Visual Studio Code**.

When I tell people that none of my computers have ROS installed on them, I mostly get puzzled looks. As soon as I try to explain people why I decided to do so and why I use ROS only from inside a Docker instead, most people become curious. At the beginning most people think it is not worth the hassle but most people give it a go and will immediately see the advantages of Docker for robotics and implement it in their workflow as well.

Over the last couple of years I have collaborated professionally with different companies and robotics research institutions and the reaction has always been the same. I have not yet quite understood why Docker as a technology has such a negative connotation. Maybe it is simply a lack of understanding, maybe this is historically grown. Anyways, my goal of this guide is to show best practices that I have found over the last couple of years working with Docker for robotic software development. In my opinion Docker as a technology is essential for developing robotics in an efficient and reliable manner.

As said I do not have ROS installed on my development computers and do not plan to do so. Instead of running a vanilla system with Docker and my IDE installed. There are a few tools for power management installed on my host machine but all project related-code is put inside a Docker. Every single workspace has its own Docker, I have Dockers for testing particular sensors and robot stacks, some in ROS1, others in ROS2, that all can be run on my host Ubuntu 22.04 system. If I need a new container that uses this sensor or robot I either copy the relevant parts from the corresponding Dockerfile or I leverage multi-layer builds to generate the new image starting from the sensor and robot images. Furthermore I might layer different workspaces on top of each other or orchestrate multiple workspaces with Docker-Compose.

This repository used to be part of [another guide](https://github.com/2b-t/docker-realtime) I have written on Docker and real-time applications. As the general Docker and ROS part has now become quite lengthy, I have decided to extract it and create a repository of its own for it.



## Why should I use Docker when developing robotics software?

- **Compatability**:
  - Working with robots in ROS generally requires working with **different Ubuntu distributions**. With Docker one can avoid having multiple partitions on the same system and instead **start different kernels from the same host system**. This way for example a ROS Indigo stack can still be run on a Ubuntu 22.04. This is very important as sooner or later robotic stacks have to be retired as they are not state-of-the-art anymore (sensors change, ROS gets replaced by ROS2) but nonetheless one should still be able to run this legacy code without having a legacy computer laying around.
  - Furthermore you can have a **non-Debian-based Linux host system** and nonetheless work with ROS if you prefer another Linux distribution over Ubuntu as your daily driver, yet have the convenience of working with Ubuntu when dealing with ROS.
- **Replicability**:
  - Robotic stacks are often very large. A single person often won't accomplish much. **Multiple people** working on the same workspace should have an **identical set-up with the same software versions**. At the same time each contributor should have a central point were IPs and other parameters can be modified (which do not have to be commited to the common repository everybody is working on together).
  - Working with **mutiple robotic stacks** on the same Ubuntu distribution often requires working with **different versions of the same library** for different projects. With Docker this is no issue.
  - As software engineers and researcher develop on a machine they will install an immense amount of software that often is not needed at all but is never uninstalled when not needed anymore. Even an experienced programmer under stress will simply search for a solution on Stackoverflow, take the post with the most upvotes - even if they do not fully understand it - and give it a go. This means no developers system is actually clean, most of them actually contain a lot of useless garbage. This useless software might impact other code, that might break it or is required to install other packages without the developer knowing, or is incompatible with other packages or certain versions. Working without a fresh system means always carrying this installation history across projects. This leads to situation where code compiles on one computer but does not compile for another person with a slightly different set-up ("But it compiles on my computer..."-situations). From my experience most of the time the reason for these situations are **implicit dependencies and restrictions** that the developer is not aware of and not the fault of the person trying to replicate the set-up. Therefore you as a programmer (or researcher) should be interested in using technologies such as Docker: After all it is your responsability to make your software project and research as replicable as possible, and isolate any previous modifications from your current project.
- **Isolation**:
  - Working with different robotic stacks generally also means working on **different networks**. This means robotic developers will generally add new robots they need to communicate with inside their **`/etc/hosts`** configuration. This might lead to collision of IPs and results in different entries having to be commented or uncommented in order to be able to work with a particular robot. Similarly most people add certain definitions and aliases inside their **`.bashrc`** that they will comment and uncomment them depending on the project they work on. This is very inconvenient, cumbersome and error-prone. When working with a Docker these **configuration files are specific to a project** and do not leak into workspaces of other robots.
- **Continuous integration**: Docker is an essential building stone of most continuous integration pipelines. Maintaining a description of the environment that code should be run in is essential for testing the code.

As guarantueeing these characteristics without the use of Docker is close to impossible, there are many companies and institutions where a robotic software stack only runs only on a particular computer. Nobody is allowed to touch (or at least make significant changes to) that system as if it breaks that robotic system would be rendered useless (or at least inoperable for some time). In my opinion such thing should never happen and is a strategic failure per se. Any robot should be replicable just from a set-up that can be found online in your version control system in a semi-automated fashion without having to go through a long manual set-up routine. A pipeline based on Docker can help with that. **Even if you do not deploy a robot with Docker you should maintain one as a back-up solution.**

## Why is Docker important in particular for academic and research institutions?

In particular research institutions are in desperate need for container-based solutions such as Docker - more than companies in my opinion:

A company usually is made of a **stable** workforce of **experienced** engineers that work together on a **few** homogeneous products. Any decent company will work towards **common tools** and will have **mechanisms** in place that should **guarantee code quality**. These products will be maintained until they reach their life cycle after several year and are either retired or replaced, resulting in an overall small variability.

Academic and research institutions are the complete opposite: Workers and students generally are **fluctuating**, might be motivated and brilliant but are at a start of their career, generally **lacking the experience**. Furthermore there are close to **no mechanisms in place that guarantee code quality**. The tools the students and research engineers will use are very **heterogeneous**. A large part of the developed code will **not be actively maintained** for an extended period as there are no resources for doing so after a project ends. At a certain point projects have to be **retired** nonetheless they should be left **in a replicable state**. Many universities and research institutions fail to have mechanisms in place that help with this. I have already seen many projects die because the main developer left not only taking with themselves the know-how but also any chance of replicating his/her work as the code only worked on their machine. This is a fatal loss for any institution in my opinion as they lost the know-how and significantly reduced their chance of replicating the work. Many research institutions I had to deal with suffer from a significant slow down due to this which significantly slows down their daily business and growth.

If you start on a new project it is incredibly frustrating to take over a project from somebody that lacks documentation. Even if you have access to their working computer you will likely have to modify their `.bashrc` and network set-up. If you further have to start over with another computer you will have to search for dependencies, fiddling with different versions of libraries and implicit undocumented dependencies. This **slows down and demotivates**. This is particularly true for Bachelor and Master students that are only with these institutions for a limited amount of time. Some might have certain constraints and want to finish their work in a certain limited time frame. This means if you are not able to get them started quickly with a project they will not only lose motivation but also lose valuable time that they could do on research for fixing set-up problems that are structural and actually none of their business. PhD students in robotics might have different backgrounds and might not be familiar with best-practices. Generally they leave after some time without anybody having a complete overview of what they did. It is essential to familiarize them with a standard workflow that allows to replicate their work. After all one of the core idea of any research is making findings **replicable**.

After all the time effort for setting up and maintaining a Docker is not bigger than installing the libraries but it only works if you immediately introduce your students and junior researchers to these technologies and not only in the middle or towards the end of the project. Furthermore Docker allows you to reset quickly, go back to a previous state. This quickly pays off in particular if more than a single computer has to be used. And the gained time can be spent on research.

Building this infrastructure and workflows also as an academic institution is a long-term investment, of similar importance to building frameworks rather than single purpose code.



## What are the drawbacks of Docker?

For robotics **software development I do not see any drawbacks with using Docker**. After all Docker is a mature technology that is used successfully in many other fields. From my experience there are many prejudices surrounding Docker as a technology but graphic user interfaces, real-time capable code, working with hardware can all be worked around in a reliable and portable manner. This guide will explain how this can be done.

On the other hand when deploying code with a Docker this might be more problematic and should be considered carefully. This is mainly as user levels inside the Docker are quite a mess (as will be also discussed later ) and therefore most people give root privileges to the Docker user. This way an intruder might gain access to the host system in particular when running a container as `privileged`.



## Structure of this guide

This guide is structured in four chapters:

- [**Introduction to Docker and Docker-Compose**](./doc/Introduction.md)
- [**Set-up with Visual Studio Code**](./doc/VisualStudioCodeSetup.md)
- [**Graphic user interfaces and Docker**](./doc/Gui.md)
- [**ROS and Docker**](./doc/Ros.md)

It is further extended by an external guide on **Docker for real-time applications with `PREEMPT_RT`** that can be found [here](https://github.com/2b-t/docker-realtime) as well as an example of such a sensor Docker for the **Intel Realsense sensors** that can be found [here](https://github.com/2b-t/realsense-ros2-docker).



