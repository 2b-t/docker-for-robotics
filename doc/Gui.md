# Graphic user interfaces inside Docker

Author: [Tobit Flatscher](https://github.com/2b-t) (August 2021 - August 2022)



## 1. Different approaches 

Running user interfaces from inside a Docker might not be its intended usage but as of now there are several options available. The problem with all of them is that most of them are specific to Linux operating systems. On the the [ROS Wiki](http://wiki.ros.org/docker/Tutorials/GUI) the different options are discussed in more detail:

- In Linux there are several ways of connecting a containers output to a host's **X server** resulting in an output which is indistinguishable from a program running on the host directly. This is the approach chosen for this guide. It is quite portable but requires additional steps for graphics cards running with nVidia hardware acceleration rather than the Linux Nouveau display driver. OSRF has also released [Rocker](https://github.com/osrf/rocker) as a tool to support mounting folders and launching graphic user interfaces. I did not use it as I try to avoid introducing unnecessary dependencies.
- Other common approaches are less elegant and often use some sort of **Virtual Network Computing (VNC)** which streams the entire desktop to the host over a dedicated window similar to connecting virtually to a remote machine. This is usually the approach chosen for other operating systems such as Windows and Macintosh but requires additional software and does not integrate as seemlessly.

The rest of the guide will focus on graphic user interfaces on Linux by exploiting X-Server. This won't work with Windows and Mac but I would not encourage using Docker on other operating systems other than Linux anyways.



## 2. Using X-Server

As pointed out before this guide uses the Ubuntu X-Server for outputting dialogs from a Docker. The Docker-Compose file with and without Nvidia hardware acceleration look differently and Nvidia hardware acceleration requires a few additional setup steps. These differences are briefly outlined in the sections below. It is worth mentioning that **just having an Nvidia card does not necessitate the Nvidia setup** but instead what matters is the **driver** used for the graphics card. If you are using a Nouveau driver for an Nvidia card then a Docker-Compose file written for hardware acceleration won't work and instead you will have to turn to the Docker-Compose file without it. And vice versa, if your card is managed by the Nvidia driver then the first approach won't work for you. This fact is in particular important for the `PREEMPT_RT` patch: You won't be able to use your Nvidia driver when running the patch. Your operating system might mistakenly tell you that it is using the Nvidia driver but it might not. It is therefore important to check the output of `$ nvidia-smi`. If it outputs a managed graphics card, then you will have to go for the second approach with hardware acceleration. If it does not output anything or is not even installed go for the Nouveau driver setup.

You can check in Software and Updates which graphics driver is currently used:

![Software & Updates](../media/ubuntu_software_and_updates.png)



In any case before being able to **stream to the X-Server on the host system** you will have to run the following command inside the **host system**:

```bash
$ xhost +local:root
```

where `root` corresponds to the user-name of the user used inside the Docker container. This command has to be **repeated after each restart** of the host system.

If you do not execute this command before launching a graphic user interface the application will not be able to connect to the display. For Rviz for example this might look as follows:

```bash
$ root@P500:/ros_ws# rosrun rviz rviz
Authorization required, but no authorization protocol specified
qt.qpa.xcb: could not connect to display :0
qt.qpa.plugin: Could not load the Qt platform plugin "xcb" in "" even though it was found.
This application failed to start because no Qt platform plugin could be initialized. Reinstalling the application may fix this problem.

Available platform plugins are: eglfs, linuxfb, minimal, minimalegl, offscreen, vnc, xcb.

Aborted (core dumped)
```



### 2.1 Nouveau and AMD driver

As pointed out in the second before this type of setup applies to any card that is not managed by an Nvidia driver, even if the card is an Nvidia card. In such a case it is sufficient to share the following few folders with the host system. The `docker-compose.yml` might look as follows:

```yaml
version: "3.9"
services:
  some_name:
    build:
      context: .
      dockerfile: Dockerfile
    tty: true
    environment:
     - DISPLAY=${DISPLAY} # Option for sharing the display
     - QT_X11_NO_MITSHM=1 # For Qt
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:rw # Share system folder
      - /tmp/.docker.xauth:/tmp/.docker.xauth:rw # Share system folder
```

### 2.2 Hardware acceleration with Nvidia cards

This section is only relevant for Nvidia graphic cards managed by the Nvidia driver or if you want to have hardware acceleration inside the Docker, e.g. for using CUDA or OpenGL. Graphic user interfaces that do not require it will work fine in any case. As also pointed out [in the ROS tutorial](http://wiki.ros.org/docker/Tutorials/Hardware%20Acceleration) having hardware acceleration is actually more tricky! Nvidia offers a dedicated [`nvidia-docker`](https://github.com/NVIDIA/nvidia-docker) (with two different options `nvidia-docker-1` and `nvidia-docker-2` which sightly differ) as well as the [`nvidia-container-runtime`](https://nvidia.github.io/nvidia-container-runtime/). Latter was chosen for this guide as it seems to be the way from now onwards and will be discussed below.

#### 2.2.1 Installing the `nvidia-container-runtime`

The installation process of the [`nvidia-container-runtime`](https://nvidia.github.io/nvidia-container-runtime/) is described [here](https://stackoverflow.com/a/59008360). Before following through with the installation make sure it is not already set-up on your system. For this check the `runtime` field from the output of `$ docker info`. If `nvidia` is available as an option already you should be already good to go.

If it is not available you should be able to install it with the following steps:

```bash
$ curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | \
  sudo apt-key add -
$ distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
$ curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list
$ sudo apt-get update
$ sudo apt-get install nvidia-container-runtime
```

and then [set-up the Docker runtime](https://github.com/NVIDIA/nvidia-container-runtime#docker-engine-setup):

```bash
$ sudo tee /etc/docker/daemon.json <<EOF
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
$ sudo pkill -SIGHUP dockerd
```

After these steps you might will have to restart the system or at least the Docker daemon with `$ sudo systemctl daemon-reload` and `$ sudo systemctl restart docker`. Then `$ docker info` should output at least two different runtimes, the default `runc` as well as `nvidia`. This runtime can be set in the Docker-Compose file and one might have to set the `environment variables` `NVIDIA_VISIBLE_DEVICES=all` and `NVIDIA_DRIVER_CAPABILITIES=all`. Be aware that this will fail when launching it on other system without that runtime. You will need another dedicated Docker-Compose file for non-nVidia graphic cards!

A Docker-Compose configuration for the Nvidia graphics cards with the Nvidia graphics driver looks as follows:

```yaml
version: "3.9"
services:
  some_name:
    build:
      context: .
      dockerfile: Dockerfile
    tty: true
    environment:
     - DISPLAY=${DISPLAY}
     - QT_X11_NO_MITSHM=1
     - NVIDIA_VISIBLE_DEVICES=all # Share devices of host system
    runtime: nvidia # Specify runtime for container
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
      - /tmp/.docker.xauth:/tmp/.docker.xauth:rw
```

Depending on how your system is configured your computer might still decide to use the integrated Intel Graphics instead of your Nvidia card in order to save power. In this case I'd recommend you to switch the Nvidia X Server (that is automatically installed with the driver) to performance mode instead of on-demand as shown in the screenshot below. This way the Nvidia card should always be used instead of the Intel Graphics.

![Nvidia X Server configuration](../media/nvidia_x_server.png)

### 2.3 Avoiding duplicate configurations

You can already see that there are quite a few common options between the two configurations. While sadly Docker-Compose does not have conditional execution (yet) one might [override or extend an existing configuration file](https://github.com/Yelp/docker-compose/blob/master/docs/extends.md) (see also [`extends`](https://docs.docker.com/compose/extends/) as well this [Visual Studio Code guide](https://code.visualstudio.com/docs/remote/create-dev-container#_extend-your-docker-compose-file-for-development)).

I normally start by creating a base Docker-Compose file `docker-compose.yml` that does not support graphic cards

```yaml
version: "3.9"
services:
  some_name:
    build:
      context: .
      dockerfile: Dockerfile
    tty: true
```

that is then extended for graphic user interfaces without Nvidia driver `docker-compose-gui.yml`,

```yaml
version: "3.9"
services:
  some_name:
    extends:
      file: docker-compose.yml
      service: some_name
    environment:
     - DISPLAY=${DISPLAY}
     - QT_X11_NO_MITSHM=1
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
      - /tmp/.docker.xauth:/tmp/.docker.xauth:rw
```

on top of that goes another Docker-Compose file with Nvidia acceleration `docker-compose-gui-nvidia.yml`

```yaml
version: "3.9"
services:
  some_name:
    extends:
      file: docker-compose-gui.yml
      service: some_name
    environment:
     - NVIDIA_VISIBLE_DEVICES=all
    runtime: nvidia
```

and finally I have yet another file which can be launched for hardware acceleration without graphic user interfaces `docker-compose-nvidia.yml` which might be used for computations and machine learning containers.

```yaml
version: "3.9"
services:
  some_name:
    extends:
      file: docker-compose.yml
      service: some_name
    environment:
     - NVIDIA_VISIBLE_DEVICES=all
    runtime: nvidia
```

This way if I need to add additional options, I only have to modify the base Docker-Compose file `docker-compose.yml` and the others will simply adapt.

I can then specify which file should be launched to Docker-Compose with e.g.

```bash
$ docker-compose -f docker-compose-gui-nvidia.yml up
```

