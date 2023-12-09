# ROS inside Docker

Author: [Tobit Flatscher](https://github.com/2b-t) (2021 - 2023)



## 1. ROS/ROS 2 with Docker

I personally think that Docker is a good choice for **developing** robotic applications as it allows you to quickly switch between different projects but **less so for deploying** software. Refer to [this Canonical article](https://ubuntu.com/blog/ros-docker) to more details about the drawbacks of deploying software with Docker, in particular regarding security. For the deployment I personally would rather turn to Debian or Snap packages (see e.g. [Bloom](http://wiki.ros.org/bloom/Tutorials/FirstTimeRelease)). But there are actually quite a few companies that I am aware of that actually use Docker for deployment as well, first and foremost [Boston Dynamics](https://dev.bostondynamics.com/docs/payload/docker_containers#).

The ROS Wiki offers tutorials on ROS and Docker [here](http://wiki.ros.org/docker/Tutorials), there is also a very useful [tutorial paper](https://www.researchgate.net/publication/317751755_ROS_and_Docker) out there and another interesting article can be found [here](https://roboticseabass.com/2021/04/21/docker-and-ros/). Furthermore a list of important commands can be found [here](https://tuw-cpsg.github.io/tutorials/docker-ros/). After installing Docker one simply pulls an image of ROS, specifying the version tag:

```bash
$ sudo docker pull ros
```

gives you the latest ROS 2 version whereas 

```bash
$ sudo docker pull ros:noetic-robot
```

will pull the latest version of ROS1.

Finally you can run it with 

```bash
$ sudo docker run -it ros
```

(where `ros` should be replaced by the precise version tag e.g. `ros:noetic-robot`).

The OSRF ROS Docker provides a readily available entrypoint script `ros_entrypoint.sh` that automatically sources `/opt/ros/<distro>/setup.bash`.

### 1.1 Folder structure

I generally structure Dockers for ROS in the following way:

```
ros_ws
├─ docker
|  ├─ Dockerfile
|  └─ docker-compose.yml # Context is chosen as ..
└─ src # Only this folder is mounted into the Docker
   ├─ .repos # Configuration file for VCS tool
   └─ packages_as_submodules
```

Each ROS-package or a set of ROS packages are bundled together in a Git repository. These are then included as submodules in the `src` folder or even better by using [VCS tool](https://github.com/dirk-thomas/vcstool). Inside the `docker-compose.yml` file one then **mounts only the `src` folder as volume** so that it can be also accessed from within the container. This way the build and devel folders remain inside the Docker container and you can compile the code inside the Docker as well as outside (e.g. having two version of Ubuntu and ROS for testing in with different distributions).

Generally I have more than a single `docker-compose.yml` as discussed in [`Gui.md`](./Gui.md) and I will add configuration folders for Visual Studio Code and a configuration for the Docker itself, as well as dedicated tasks. I usually work inside the container and install new software there first. I will keep then track of the installed software manually and add it to the Dockerfile as soon as it has proved useful.

### 1.2 Docker configurations

You will find quite a few Docker configurations for ROS online, in particular [this one](https://github.com/athackst/vscode_ros2_workspace) for ROS 2 is quite well made. Another one for ROS comes with this repository.

### 1.4 Larger software stacks

When working with larger software stacks tools like [Docker-Compose](https://docs.docker.com/compose/) and [Docker Swarm](https://docs.docker.com/engine/swarm/stack-deploy/) might be useful for **orchestration**, in particular when deploying with Docker. This is discussed in several separate repositories such as [this one](https://github.com/fujitatomoya/ros_k8s) by Tomoya Fujita, member of the Technical Steering Committee of ROS2.

## 2. ROS

This section will got into how selected ROS 1 configuration settings can be simplified with Docker, in particular the network set-up.

### 2.1 External ROS master

Sometimes you want to run nodes inside the Docker and communicate with a ROS master outside of it. This can be done by adding the following **environment variables** to the `docker-compose.yml` file

```bash
 9    environment:
10      - ROS_MASTER_URI=http://localhost:11311
11      - ROS_HOSTNAME=localhost
```

where in this case `localhost` stands for your local machine (the loop-back device `127.0.0.1`).

#### 2.1.1 Multiple machines

In case you want the Docker to communicate with another device on the network be sure to activate the option

```bash
15    network_mode: host
16    extra_hosts:
17      - "my_device:192.168.100.1"
```

as well, where `my_device` corresponds to the host name followed by its IP. The **`extra_hosts`** option basically adds another entry to your **`/etc/hosts` file inside the container**, similar to what you would do manually normally in the [ROS network setup guide](https://wiki.ros.org/ROS/NetworkSetup). This way the network set-up inside the Docker does not pollute the host system.

Now make sure that pinging works **in both directions**. In case there was an issue with a firewall (or VPN) pinging might only work in one direction. If you would continue with your set-up you might be able to receive information (e.g. visualize the robot and its sensors) but not send it (e.g. command the robot). Furthermore ROS relies on the correct host name being set: If it does not correspond to the name of the remote computer the communication might also only work in one direction. For time synchronization of multiple machines it should be possible to run [`chrony`](https://robofoundry.medium.com/how-to-sync-time-between-robot-and-host-machine-for-ros2-ecbcff8aadc4) from inside a container without any issues. For how this can be done please refer to [cturra/ntp](https://github.com/cturra/docker-ntp) or alternatively to [this guide](http://www.freekb.net/Article?id=3292). After setting it up use `$ chronyc sources` as well as `$ chronyc tracking` to verify the correct set-up.

You can test the communication between the two machines by sourcing the environment, launching a `roscore` on your local or remote computer, then launch the Docker source the local environment and see if you can see any topics inside `$ rostopic list`. Then you can start publishing a topic `$ rostopic pub /testing std_msgs/String "Testing..." -r 10` on one side (either Docker or host) and check if you receive the messages on the other side with `$ rostopic echo /testing`. If that works fine in both directions you should be ready to go. If it only works in one direction check your host configuration and your `ROS_MASTER_URI` and `ROS_HOSTNAME` environement variables.

As a best practice I normally use a  [`.env` file](https://vsupalov.com/docker-arg-env-variable-guide/) that I place in the same folder as the `Dockerfile` and the `docker-compose.yaml` containing the IPs:

```bash
CATKIN_WORKSPACE_DIR="/catkin_ws"
YOUR_IP="192.168.100.2"
ROBOT_IP="192.168.100.1"
ROBOT_HOSTNAME="some_host"
```

The IPs inside this file can then be modified and are used inside the Docker-Compose file to set-up the container: The `/etc/hosts` file as well as the `ROS_MASTER_URI` and the `ROS_HOSTNAME`:

```yaml
version: "3.9"
services:
  ros_docker:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    environment:
      - ROS_MASTER_URI=http://${ROBOT_IP}:11311
      - ROS_IP=${YOUR_IP}
    network_mode: "host"
    extra_hosts:
      - "${ROBOT_HOSTNAME}:${ROBOT_IP}"
    tty: true
    volumes:
      - ../src:/${CATKIN_WORKSPACE_DIR}/src
```

In order to update the IPs though with this approach you will have to rebuild the container. As long as you did not make any modifications to the Dockerfile it should though use the cached layers and should be very quick. But any progress inside the container will be lost when switching IP!

An example configuration can be found [here](../templates/ros/docker).

#### 2.1.2 Combining different package and ROS versions

Combining different ROS 1 versions is not officially supported but largely works as long as message definitions have not changed. This is problematic with constantly evolving packages such as [Moveit](https://moveit.ros.org/). The interface between the containers in this case has to be chosen wisely such that the used messages do not change across between the involved distributions. You can use [`rosmsg md5 <message_type>`](https://wiki.ros.org/rosmsg#rosmsg_md5) in order to verify quickly if the message definitions have changed: If the two `md5` hashes are the same then the two distributions should be able to communicate via this message. And even if the message hashes are different you might go ahead and compile the message, as well as packages depending on it, from source (do not forget to uninstall the ones installed through Debian packages). This way both distributions will have again the same message definitions.

### 2.3 Healthcheck

Docker gives you the possibility to [add a custom healthcheck to your container](https://docs.docker.com/engine/reference/builder/#healthcheck). This test should tell Docker whether your container is working correctly or not. Such a healthcheck can be defined from inside the Dockerfile or from a Docker-Compose file.

In a Dockerfile it might look as follows:

```dockerfile
HEALTHCHECK [OPTIONS] CMD command
```

such as

```dockerfile
HEALTHCHECK CMD /ros_entrypoint.sh rostopic list || exit 1
```

or anything similar.

While for [Docker-Compose](https://docs.docker.com/compose/compose-file/compose-file-v3/#healthcheck) you might add something like:

```yaml
 9    healthcheck:
10      test: /ros_entrypoint.sh rostopic list || exit 1
11      interval: 1m30s
12      timeout: 10s
13      retries: 3
14      start_period: 1m
```

## 3. ROS 2

ROS 2 replaces the traditional custom [TCP](https://wiki.ros.org/ROS/TCPROS)/[UDP](https://wiki.ros.org/ROS/UDPROS) communication with [DDS](https://design.ros2.org/articles/ros_on_dds.html). As a result the [`ROS_DOMAIN_ID`](https://docs.ros.org/en/humble/Concepts/About-Domain-ID.html) replaces the IP-based set-up. For a container this means one would create a `ROS_DOMAIN_ID` environment variable that again might be controlled by an [`.env` file](https://vsupalov.com/docker-arg-env-variable-guide/):

```yaml
 9    environment:
10      - ROS_DOMAIN_ID=1 # Any number in the range of 0 and 101; 0 by default
```

Choosing a safe range for the Domain ID largely depends on the operating system and is described in more details in the [corresponding article](https://docs.ros.org/en/humble/Concepts/About-Domain-ID.html). There might be [additional settings for a DDS client such as telling it which interfaces to use](https://iroboteducation.github.io/create3_docs/setup/xml-config/). For this purpose it might make sense to mount the corresponding DDS configuration file into the Docker.

Another thing you might want to configure is the **DDS middleware** to be used. In ROS 2 one might choose between different (free or payment) middleware implementations such as FastDDS and CycloneDDS. This will be outlined in more detail in the next section.

What I generally do is define the corresponding environment variables such as [`RMW_IMPLEMENTATION`](https://docs.ros.org/en/humble/How-To-Guides/Working-with-multiple-RMW-implementations.html) and [`CYCLONEDDS_URI`](https://cyclonedds.io/docs/cyclonedds/latest/config/index.html) in the case of cyclone and mount the dds configuration as a volume inside the container.

```yaml
 9    environment:
10      - RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
11      - CYCLONEDDS_URI=${AMENT_WORKSPACE_DIR}/dds/cyclone.xml
12    network_mode: "host"
13    volumes:
14      - ../dds:${AMENT_WORKSPACE_DIR}/dds
```

For an example of what this configuration might look like have a look at [this folder](../templates/ros2/docker).

## 4. Bridging ROS 1 and ROS 2

Setting the DDS middleware as described above is in particular important for cross-distro communication as **different ROS distros** ship with [**different default DDS implementations**](https://docs.ros.org/en/humble/Installation/DDS-Implementations.html). Neither communication between different DDS implementations nor different ROS 2 distributions is currently officially supported (for more details see [here](https://github.com/ros2/ros2_documentation/issues/3288)) but similarly to ROS 1 if the **messages have not changed** (or you compile the messages as well as the packages using them from source) and you are **using the same DDS vendor across all involved distros** generally communication between the different distros can be achieved. This can also be useful for **bridging ROS 1 to ROS 2**. The last Ubuntu version to support both ROS 1 (Noetic) and ROS 2 (Galactic) is Ubuntu 20.04. You can use the corresponding [**Galactic ROS 1 bridge Docker**](https://hub.docker.com/layers/library/ros/galactic-ros1-bridge/images/sha256-a2f06953930b0a209295138745d606b1936f0b0564106df9230e2a6612b8b9a2?context=explore). In case message definitions have changed from Galactic to the distro that you are using (the ROS 2 API is not stable yet!) you might have to compile the corresponding messages from source. The main advantage over other solutions for having the two run alongside is that unlike to other solutions ([here](https://docs.ros.org/en/humble/How-To-Guides/Using-ros1_bridge-Jammy-upstream.html) or [here](https://github.com/TommyChangUMD/ros-humble-ros1-bridge-builder/tree/main)) you will have none or only very few repositories that have to be compiled from source and can't be installed from a Debian package.

