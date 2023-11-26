# Introduction to Docker

Author: [Tobit Flatscher](https://github.com/2b-t) (2021 - 2023)



## 1. Challenges in software deployment

Deploying a piece of software in a portable manner is a non-trivial task. Clearly there are different operating system and different software architectures which require different binary code, but even if these match you have to make sure that the compiled code can be executed on another machine by supplying all its **dependencies**.

Over the years several different packaging systems for different operating systems have emerged that provide methods for installing new dependencies and managing existing ones in an coherent manner. The low-level package manager for Debian-based Linux operating systes is [`dpkg`](https://wiki.debian.org/Teams/Dpkg), while for high-level package management, fetching packages from remote locations and resolving complex package relations, generally [`apt`](https://wiki.debian.org/Apt) is chosen. `apt` handles retrieving, configuring, installing as well as removing packages in an automated manner. When installing an  `apt` package it checks the existing dependencies and installs only those that are not available yet on the system. The dependencies are shared, making the packages smaller but not allowing for multiple installations of the same library and potentially causing issues between applications requiring different versions of the same library. Contrary to this the popular package manager [`snap`](https://snapcraft.io/) uses self-contained packages which pack all the dependencies that a program requires to run, allowing for multiple installations of the same library.  **Self-contained** boxes like these are called **containers**, as they do not pollute the rest of the system and might only have limited access to the host system. The main advantage of containers is that they provide clean and conistent environments as well as isolation from the hardware.



## 2. Docker to the rescue

[**Docker**](https://www.docker.com/) is another **framework** for working with **containers**. A [Docker - contrary to `snap`](https://www.youtube.com/watch?v=0z3yusiCOCk) - is not integrated in terms of hardware and networking but instead has its own IP address, adding an extra layer of abstraction. A Docker container is similar to a virtual machine but the containers share the same kernel like the host system: Docker does not **virtualise** on a hardware level but on an **app level** (OS-level virtualisation). For this Docker builds on a virtualization feature of the Linux kernel, [namespaces](https://en.wikipedia.org/wiki/Linux_namespaces), that allows to selectivelty grant processes access to kernel resources. As such Docker has its own namespaces for `mnt`, `pid`, `net`, `ipc` as well as `usr` and its own root file system. As a Docker container uses the same kernel, and as a result also the same scheduler one might achieve native performance. At the same time this results in issues with graphic user interfaces as these are not part of the kernel itself and thus not shared between the container and the host system. These problems can be worked around though mostly.

Using Docker brings a couple of advantages as it strongly leverages on the decoupling of the kernel and the rest of the operating system:

- **Portability**: You can run code not intended for your particular Linux distribution (e.g packages for Ubuntu 20.04 on Ubuntu 18.04 and vice versa) and you can mix them, launching several containers with different requirements on the same host system by means of dedicated [orchestration tools](https://docs.docker.com/get-started/orchestration/) such as [Kubernetes](https://kubernetes.io/) or [Docker Swarm](https://docs.docker.com/engine/swarm/). This is a huge advantage for robotics applications as one can mix containers with different ROS distributions on the same computer running in parallel, all running on the same kernel of the host operating system, governed by the same scheduler.
- **Performance**: Contrary to a virtual machine the performance penalty is very small and for most applications is indistinguishable from running code on the host system: After all it uses same kernel and scheduler as the host system.
- Furthermore one can also run a **Linux container on a Windows or MacOS operating system**. This way you lose though a couple of advantages of Docker such as being able to run real-time code as there will be a light-weight virtual machine underneath emulating a Linux kernel.

This way one can guarantee a **clean, consistent and standardised build environment** while maintaining encapsulation and achieving native performance.

The core component of Docker are so called **images**, *immutable read-only templates*, that hold source code, libraries and dependencies. These can be layered over each other to form more complex images. **Containers** on the other hand are the *writable layer* on top of the read-only images. By starting an image you obtain a container: Images and containers are not opposing objects but they should rather be seen as different phases of building a containerised application.

The Docker **daemon** software manages the different containers that are available on the system: The generation of an image can be described by a so called **`Dockerfile`**. A Dockerfile is like a recipe describing how an image can be created from scratch. This file might help also somebody reconstruct the steps required to get a code up and running on a vanilla host system without Docker. It is so to speak self-documenting and does not result in an additional burden like a wiki. Similarly one can recover the steps performed to generate an image with [`$ docker history --no-trunc <image_id>`](https://docs.docker.com/engine/reference/commandline/history/). Dedicated servers, so calle **Docker registries** (such as the [Docker Hub](https://hub.docker.com/) or [Github's GHCR](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)), allow you to store and distribute your Docker images. These image repositories hold different images so that one does not have to go through the build process but instead can upload and download them directly, speeding up deployment. Uploads might also be triggered by a continuous integration workflow like outlined [here](https://docs.github.com/en/actions/publishing-packages/publishing-docker-images).

On top of this there go other toolchains for managing the lifetime of containers and orchestration multiple of them such as [Docker-Compose](https://docs.docker.com/compose/), [Swarm](https://docs.docker.com/engine/swarm/) or [Kubernetes](https://kubernetes.io/).

This makes Docker in particular suitable for **deploying source code in a replicable manner** and will likely speed-up your development workflow. Furthermore one can use the description to perform tests or compile the code on a remote machine in terms of [continuous integration](https://en.wikipedia.org/wiki/Continuous_integration). This means for most people working professional on code development it comes at virtually no cost.



## 3. Installing Docker

Docker is installed pretty easily. The installation guide for **Ubuntu** can be found [here](https://docs.docker.com/engine/install/ubuntu/). It basically boils down to a five steps:

```bash
$ sudo mkdir -m 0755 -p /etc/apt/keyrings
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
$ echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io
```

After installation you will want to make sure that Docker can be **run without `sudo`** as described [here](https://docs.docker.com/engine/install/linux-postinstall/):

```bash
$ sudo groupadd docker
$ sudo usermod -aG docker $USER
```

Finally log out and log back in again.



## 4. Usage

Similarly the usage is very simple, you need a few simple commands to get a Docker up and running which are discussed in the file below.

### 4.1 Launching a container from an image

As discussed above you can pull an image from the [Dockerhub](https://hub.docker.com/) and launch it as a container. This can be done by opening a console and typing:

```bash
$ docker run hello-world
```

`hello-world` is an image intended for testing purposes. After executing the command you should see some output to the console that does not contain any error messages. In case you are not able to run the command above, prepend it with `sudo` and retry. If this works please go back to the previous section and enable `sudo`less Docker as this will be crucial for e.g. the Visual Studio Code set-up.

If you want to find out what other images you could start from just [browse the Dockerhub](https://hub.docker.com/), e.g. for [Ubuntu](https://hub.docker.com/_/ubuntu). You will see that there are different versions with corresponding tags available. For example to run a Docker with Ubuntu 20.04 installed you could use the tag `20.04` or `focal` resulting e.g. in the command

```bash
$ docker run ubuntu:focal
```

This should not output anything and should immediately return. The reason for this is that each container has an [entrypoint](https://docs.docker.com/engine/reference/builder/#entrypoint). This script will be run and as soon as it terminates the container will return to the command line. This is actually the basic idea of a Docker container: A container should be responsible for a single service. Once this service stops it should return again.

If you want to keep the container open you have to open it in **interactive** mode by specifying the flag `-i` and the `-t` for opening a terminal

```bash
$ docker run -it ubuntu:focal
```

In case you need to run another command in parallel you might have to open a second terminal and connect to this Docker. In this case it is more convenient to relaunch the container with a specified `name` (or use the default one displayed by `docker run`)

```bash
$ docker run -it --name ubuntu_test ubuntu:focal
```

Now we can connect to it from another console with

```bash
$ docker exec -it ubuntu_test sh
```

The last command `sh` corresponds to the type of connection, in our case `shell`.

With the `$ exit` command the Docker can be shut down.

### 4.2 Setting-up a `Dockerfile`

Now that we have seen how to start a container from an existing image let us build a `Dockerfile` that defines steps that should be executed on the image:

```dockerfile
# Base image
FROM ubuntu:focal

# Define the workspace folder (e.g. where to place your code)
# We define a variable so that we can re-use it
ENV WS_DIR="/code"
WORKDIR ${WS_DIR}

# Copy your code into the folder (see later for better alternatives!)
COPY . WORKDIR

# Use Bourne Again Shell as default shell
SHELL ["/bin/bash", "-c"] 

# Disable user dialogs in apt installation messages
ARG DEBIAN_FRONTEND=noninteractive

# Commands to perform on base image
RUN apt-get -y update \
 && apt-get -y install some_package \
 && git clone https://github.com/some_user/some_repository some_repo \
 && cd some_repo \
 && mkdir build \
 && cd build \
 && cmake .. \
 && make -j$(nproc) \
 && make install \
 && rm -rf /var/lib/apt/lists/*

# Enable apt user dialogs again
ARG DEBIAN_FRONTEND=dialog

# Define the script that should be launched upon start of the container
ENTRYPOINT ["/code/src/my_script.sh"]
```

When saving this as `Dockerfile` (without a file ending) and type:

```bash
$ docker build -f Dockerfile .
```

Then read the available images with 

```
$ docker image ls
  REPOSITORY   TAG      IMAGE ID     CREATED   SIZE
  <none>       latest   <image_id>   ...       ...
```

You should see your newly created image.

You can launch it with

```bash
$ docker run -it <image_id>
```

As soon as you starting building complex containers you will see that the compilation might be quite slow as a lot of data might have be to installed. If you want to execute it again though or you add a command to the `Dockerfile` the container will start pretty quickly. Docker itself caches the compiled images and re-uses them if possible. In fact each individual `RUN` etc. command forms a layer of its own that might be re-used. It is therefore crucial to avoid conflicts between different layers, e.g. by [introducing each `apt-get -y install` with an `apt-get update`](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run). They have to be combined in the same `RUN` command though to be effective. Similarly you can benefit from this caching by [ordering the different layers from less frequent to most frequently changed](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#use-multi-stage-builds). This way you might reduce the time you spend re-compiling significantly.

At the same time it is also important to make the images as slim as possible removing all undesired artifacts from the images that are not necessary. For `apt` this means deleting the `apt` list after each layer again

```bash
rm -rf /var/lib/apt/lists/*
```

A simple solution to this are [multi-stage builds](https://docs.docker.com/build/building/multi-stage/) where multiple `FROM` statements are used within the same Dockerfile and parts are selectively copied between the different stages. This way everything that is not needed can be left behind.

Additionally one should set the `DEBIAN_FRONTEND` environment variable to `noninteractive` before installing any packages with `apt`. Else building the Dockerfile might fail!

### 4.3 Managing data

As you have seen above we copied the data of the current directory into the container with the `COPY` command. This means though that our changes will not affect the local code, instead we are working on a copy of it. This is often not desirable. Most f the time you actually want to mount your folders and shared them between the host system and the container. 

There are several approaches for [managing data](https://docs.docker.com/storage/) with a Docker container. Generally one stores the relevant code outside the Docker on the host system, mounting files and directories into the container, while leaving any built files inside it. This way the files relevant to both systems can be accessed inside and outside the Docker. This is generally done with [volumes](https://docs.docker.com/storage/volumes/). This results in [additional flags](https://docs.docker.com/storage/volumes/) that have to be supplied when running the Docker:

```bash
$ docker run -it <image_id> --volume:<from_host_directory>:<to_container_directory>
```

### 4.4 Build and run scripts

As you can imagine when specifying start-up options like `-it`, mounting volumes, setting up the network configuration, display settings for graphic user interfaces, passing a user name to be used inside the Docker etc. the commands for building and running Docker containers can get pretty lengthy and complicated such as the one below:

```bash
$ docker run -it --volume=../src:/code/src --name=my_container --env=DISPLAY \
  --env=QT_X11_NO_MITSHM=1 --volume=/tmp/.X11-unix:/tmp/.X11-unix:rw \
  --volume=/tmp/.docker.xauth:/tmp/.docker.xauth:rw --entrypoint='/bin/bash' <image_id>
```

To simplify this process people often create bash scripts that store these arguments for them. Instead of typing a long command commonly one just call scripts like `build_image.bash` and `container_start.bash`. This can though be quite unintuitive for other users as there does not exist a common convention for doing so. Therefore tools like Docker-Compose, which is discussed in the next section, try to simplify this process by providing standardized configuration files for it.

In any case try to avoid the `privileged` flag. If you run into any issue with not being able to do something, running the container as `privileged` will almost always solve it but there will be a more clean way. The `privileged` option breaks encapsulation and as such might pose a security risk.

At the same time it makes sense to pass crucial information into the container by means of environment variables.

### 4.5 Using a Docker registry: Dockerhub

Instead of creating our Docker image from a Docker file we might want to use a more complex existing one from a Docker registry. For this we will use the official one in the following example, the [Dockerhub](https://hub.docker.com/).

Let's begin by logging in and pulling an existing image from an existing repository that you might have found [browsing the Dockerhub](https://hub.docker.com/search).

```bash
$ docker login --username=<user> --email=<e@mail.com> # If it is public we can pull also without logging in
$ docker pull <repo>:<tag> # Pull an image from the server
```

This should give as a new image on our local computer that we can run

```bash
$ docker images # List all locally available images
  REPOSITORY   TAG      IMAGE ID       CREATED   SIZE
  <repo>       <tag>    <image_id>     ...       ...
$ docker run -it <image_id>:<tag> bin/bash # Run the image as a container
  <user>@<container_id>:/#
```

Now we can make changes to the container and finally exit it with `exit`. We should be able to see it with the following command:

```bash
$ docker ps -a # Show all containers
  CONTAINER ID     IMAGE             COMMAND   CREATED   STATUS   PORTS  NAMES
  <container_id>   <image_id>:<tag>  ...       ...       ...      ...    ...
```

Finally we can commit our changes to a new image and push this image to the Dockerhub as follows:

```bash
$ docker commit <container_id> <image_name>:<tag> # Commit container to new image
$ docker images # List all available images
  REPOSITORY     TAG      IMAGE ID       CREATED   SIZE
  <image_name>   <tag>    <image_id>     ...       ...
  <repo>         ...      ...            ...       ...
$ docker tag <image_id> <user>/<repo>:<tag> # Tag the image
$ docker push <user>/<repo> # Push the image to the server
```

### 4.6 Exporting a Docker image to file

Accessing most Docker registries will require internet access. Therefore when dealing with a slow network connection or an offline computer, sometimes it might be convenient to save a Docker image to the disk, copy them to the machine without internet access and load them onto that system:

```bash
$ docker save <repo>:<tag> > <file.tar> # Save Docker to file
$ docker load --input <file.tar> # Load Docker on other computer without internet access
```



## 5. Docker-Compose

There are different tools available that simplify the management and the orchestration of these Docker containers, such as [Docker-Compose](https://docs.docker.com/compose/reference/up/). As said supplying arguments to Docker for building and running a `Dockerfile` often results in lengthy `shell` scripts. One way of decreasing complexity and [tidying up the process](https://docs.docker.com/compose/) is by using [**Docker-Compose**](https://docs.docker.com/compose/). It is a tool that can be used for defining and running multi-container Docker applications but is also very useful for a single container. In a Yaml file such as **`docker-compose.yml`** one describes the services that an app consists of (see [here](https://github.com/compose-spec/compose-spec/blob/master/spec.md) for the syntax) and which options it should be started with. There are though a few corner cases where Docker-Compose is not powerful enough. For example it can't execute commands on the host system in order to obtain parameters that are then passed to the Docker. Parameters have to be supplied in the form of text or in the form of an environment file.

### 5.1 Installation

Prior to Ubuntu 20.04 Docker-Compose had to be installed separately like described [here](https://docs.docker.com/compose/install/). For Ubuntu 20.04 onwards it should come with Docker directly. Depending on the version you will have to call it with

```bash
$ docker compose --version
```

or `$ docker-compose --version`.

### 5.2 Writing and launching a Docker-Compose file

For example the rather complicated Docker run command given before could be expressed in Docker-Compose with the hierarchical `yml` file, generally named `docker-compose.yml`:

```yaml
version: "3.9"
services:
  my_service:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    container_name: my_container
    tty: true
    environment:
      - DISPLAY=${DISPLAY}
      - QT_X11_NO_MITSHM=1
    volumes:
      - ../src:/code/src
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
      - /tmp/.docker.xauth:/tmp/.docker.xauth:rw
    command: '/bin/bash'
```

After having created both a `Dockerfile` as well as a `docker-compose.yml` you can launch them with:

```bash
$ docker compose -f docker-compose.yml build
$ docker compose -f docker-compose.yml up
```

where with the option `-f` a Docker-Compose file with a different filename can be provided. If not given it will default to `docker-compose.yml`.

More generally such a file might hold multiple services:

```yaml
version: "3.9"
services:
  some_service: # Name of the particular service (Equivalent to the Docker --name option)
    build: # Use Dockerfile to build image
      context: . # The folder that should be used as a reference for the Dockerfile and mounting volumes
      dockerfile: Dockerfile # The name of the Dockerfile
    container_name: some_container
    stdin_open: true # Equivalent to the Docker -i option
    tty: true # Equivalent to the Docker docker run -t option
    volumes:
      - /a_folder_on_the_host:/a_folder_inside_the_container # Source folder on host : Destination folder inside the container
  another_service:
    image: ubuntu/20.04 # Use a Docker image from Dockerhub
    container_name: another_container
    volumes:
      - /another_folder_on_the_host:/another_folder_inside_the_container
volumes:
  - ../yet_another_folder_on_host:/a_folder_inside_both_containers # Another folder to be accessed by both images
```

If instead you wanted only to run a particular service you could do so with:

```bash
$ docker compose -f docker-compose.yml run my_service
```

Then similarly to the previous section one is able to connect to the container from another console with

```bash
$ docker compose exec <docker_name> sh
```

where `<docker_name>` is given by the name specified in the `docker-compose.yml` file and `sh` stands for the type of comand to be execute, in this case we open a `shell`.
