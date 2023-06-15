# ROS inside Docker

Author: [Tobit Flatscher](https://github.com/2b-t) (August 2021 - February 2023)



## 1. Working with hardware

When working with **hardware that use the network interface** such as EtherCAT slaves one might have to **share the network** with the host or remap the individual ports manually. One can automate the generation of the entries in the `/etc/hosts` file inside the container as follows:

```yaml
 9    network_mode: "host"
10    extra_hosts:
11      - "${REMOTE_HOSTNAME}:${REMOTE_IP}"
```

When sharing **external devices** such as USB devices one will have to **share the `/dev` directory** with the host system as well as use [**device whitelisting**](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/resource_management_guide/sec-devices) as follows. An overview over the IDs of the Linux allocated devices can be found [here](https://www.kernel.org/doc/html/v4.15/admin-guide/devices.html). You will have to specify the [Linux device drivers major and minor number](https://www.oreilly.com/library/view/linux-device-drivers/0596000081/ch03s02.html). Inserting a `*` will give it access to all major/minor numbers. See e.g. what this would look like for the Intel Realsense depth cameras:

```yaml
 9    volumes:
10      - /dev:/dev
11    device_cgroup_rules:
12      - 'c 81:* rmw'
13      - 'c 189:* rmw'
```

The association of these numbers and the devices is given in [`/proc/devices`](https://unix.stackexchange.com/questions/198950/how-to-get-a-list-of-major-number-driver-associations).

### 1.1 Determining `device_cgroup_rules` for connected devices

If we have no idea what `device_cgroup_rules` we might need for a particular device but we have the device at hand we might do the following.

There are a couple of ways to associate a given device and its `/dev` path (e.g. see [here](https://unix.stackexchange.com/a/144735) for a script). I normally do [the following](https://unix.stackexchange.com/questions/81754/how-to-match-a-ttyusbx-device-to-a-usb-serial-device) manually, in this case for a [Life Performance Research LPMS-IG1 IMU](https://www.lp-research.com/9-axis-imu-with-gps-receiver-series/):

I first check the connected devices with lsub, potentially unplugging and plugging it in again to see which is which:

```bash
$ lsusb
...
Bus 003 Device 008: ID 10c4:ea60 Silicon Labs CP210x UART Bridge
...
```

You might be interested in more details about the device `$ lsusb -d 10c4:ea60 -v`.

To see which `/dev` path is associated with it I will check the output of:

```bash
$ ls -l /sys/bus/usb-serial/devices
total 0
lrwxrwxrwx 1 root root 0 May 18 00:20 ttyUSB0 -> ../../../devices/pci0000:00/0000:00:14.0/usb3/3-5/3-5.4/3-5.4:1.0/ttyUSB0
$ grep PRODUCT= /sys/bus/usb-serial/devices/ttyUSB0/../uevent
PRODUCT=10c4/ea60/100
```

This means that `ttyUSB0` is assocated to `10c4:ea60` which is the device I am looking for.

Now I will check the associated major and minor number with:

```bash
$ ls -l /dev
...
crw-rw----   1 root  dialout 188,   0 May 17 23:51 ttyUSB0
...
```

In my case major `188`, minor `0` for `ttyUSB0`, my device `10c4:ea60`.

This means I will add a `device_cgroup_rule` that looks as follows:

```yaml
 9    volumes:
10      - /dev:/dev
11    device_cgroup_rules:
12      - 'c 188:* rmw'
```

I will not consider the minor version as it might change depending on what other devices are connected.
