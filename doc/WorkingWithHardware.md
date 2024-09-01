# Accessing hardware inside a container

Author: [Tobit Flatscher](https://github.com/2b-t) (2021 - 2023)



## 1. Working with hardware

When working with **hardware that use the network interface** such as EtherCAT slaves one might have to **share the network** with the host or remap the individual ports manually. One can automate the generation of the entries in the `/etc/hosts` file inside the container as follows:

```yaml
 9    network_mode: "host"
10    extra_hosts:
11      - "${REMOTE_HOSTNAME}:${REMOTE_IP}"
```

In this case the two environment variables are defined inside a `.env` file that is automatically passed to Docker Compose.

When sharing **external devices** such as USB devices one will have to **share the `/dev` directory** with the host system as well as use [**device whitelisting**](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/resource_management_guide/sec-devices) as follows (for some applications Docker's [`--device`](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) flag might be sufficient). An overview over the IDs of the Linux allocated devices can be found [here](https://www.kernel.org/doc/html/v4.15/admin-guide/devices.html). You will have to specify the [Linux device drivers major and minor number](https://www.oreilly.com/library/view/linux-device-drivers/0596000081/ch03s02.html). Inserting a `*` will give it access to all major/minor numbers. See e.g. what this would look like for the Intel Realsense depth cameras:

```yaml
 9    volumes:
10      - /dev:/dev
11    device_cgroup_rules:
12      - 'c 81:* rmw'
13      - 'c 189:* rmw'
```

The association of these numbers and the devices is given in [`/proc/devices`](https://unix.stackexchange.com/questions/198950/how-to-get-a-list-of-major-number-driver-associations).

You might also selectively mount only some USB devices:

```yaml
 9    volumes:
10      - /dev/some_device:/dev/some_device
11      - /dev/another_device:/dev/another_device
```

In case you are not quite sure which group a device belongs to you might also run the container with extended privileges as [**`privileged`**](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities). Note that this is in **generally not recommended** as this basically removes all types of isolation and as such might pose a security risk in particular when being `root` inside the container. In some rare cases this can't be avoided though (e.g. in the case of a Realsense camera with IMU that currently needs [write access to `/sys` which is not possible in an unprivileged container](https://forums.docker.com/t/unable-to-mount-sys-inside-the-container-with-rw-access-in-unprivileged-mode/97043)).

### 1.1 Determining `device_cgroup_rules` for connected devices

If we have no idea what `device_cgroup_rules` we might need for a particular device but we have the device at hand we might do the following to find out.

In Linux differentiates between **busses** (the busses on the motherboard that a device is attached to, e.g. the output of `$ lsusb`) and **device files** (located inside `/dev` that are used to abstract standard devices and communicate with the corresponding physical or virtual devices). Depending on the type of the data that is exchange one differentiates between block `b` and character `c` devices (for more information see e.g. [here](https://www.baeldung.com/linux/dev-directory)). For the busses there exist readily available tools like `lsusb` that are able to translate the vendor and product codes into human-readable strings while I am not aware of such a tool for device files.

So in order for finding out which device files (and as a consequence which device drivers major and minor numbers) belong to a device, you either have to plug the device in an out comparing the changes in device files or find out which device files belong to which bus.

#### 1.1.1 Manually unplugging devices

The easier way (that also works in some corner cases like virtual devices) is to simply read all devices files, plug the device in or out and read again all devices files and compare them to the ones prior:

```bash
$ ls -l /dev > before.txt # After this command plug the device in
$ ls -l /dev > after.txt
$ diff before.txt after.txt
...
crw-rw----   1 root  dialout 188,   0 Feb  4 16:00 ttyUSB0
...
```

This outputs directly the major (in this case 188) and minor (in this case 0) device driver numbers (in this case for a [Life Performance Research LPMS-IG1 IMU](https://www.lp-research.com/9-axis-imu-with-gps-receiver-series/)).

Sometimes you can already guess from the given date which of the device files belong to your device.

This means I will add a `device_cgroup_rule` that looks as follows:

```yaml
 9    volumes:
10      - /dev:/dev
11    device_cgroup_rules:
12      - 'c 188:* rmw'
```

Do not consider the minor version as it might change depending on what other devices are connected.

#### 1.2.1 Through `lsusb`

Another way of doing so is to connect the information from `lsusb` to the device file using the vendor and product information. There are a couple of ways to associate a given device and its `/dev` path.

The probably easiest way is to simply run [the following script](https://unix.stackexchange.com/a/144735)

```bash
#!/bin/bash

for sysdevpath in $(find /sys/bus/usb/devices/usb*/ -name dev); do
    (
        syspath="${sysdevpath%/dev}"
        devname="$(udevadm info -q name -p $syspath)"
        [[ "$devname" == "bus/"* ]] && exit
        eval "$(udevadm info -q property --export -p $syspath)"
        [[ -z "$ID_SERIAL" ]] && exit
        echo "/dev/$devname - $ID_SERIAL"
    )
done
```

This should already output something like

```bash
...
/dev/ttyUSB0 - Silicon_Labs_CP2102_USB_to_UART_Bridge_Controller_IG1232600680056
...
```

I normally do [the following](https://unix.stackexchange.com/questions/81754/how-to-match-a-ttyusbx-device-to-a-usb-serial-device) manually: I first check the connected devices with `lsusb`, potentially unplugging and plugging it in again to see which is which:

```bash
$ lsusb -tvv
...
/:  Bus 03.Port 1: Dev 1, Class=root_hub, Driver=xhci_hcd/15p, 480M
    ID 1d6b:0002 Linux Foundation 2.0 root hub
    /sys/bus/usb/devices/usb3  /dev/bus/usb/003/001
    |__ Port 5: Dev 2, If 0, Class=Hub, Driver=hub/4p, 480M
        ID 17aa:1034  
        /sys/bus/usb/devices/3-5  /dev/bus/usb/003/002
        |__ Port 4: Dev 8, If 0, Class=Vendor Specific Class, Driver=cp210x, 12M
            ID 10c4:ea60 Silicon Labs CP210x UART Bridge
            /sys/bus/usb/devices/3-5.4  /dev/bus/usb/003/008
...
```

You might be interested in more details about the device `$ lsusb -d 10c4:ea60 -v`.

To see which `/dev` path is associated with it I will check the output of:

```bash
$ ls -l /sys/bus/usb-serial/devices # And /sys/bus/usb/devices
total 0
lrwxrwxrwx 1 root root 0 Feb  4 16:00 ttyUSB0 -> ../../../devices/pci0000:00/0000:00:14.0/usb3/3-5/3-5.4/3-5.4:1.0/ttyUSB0
$ grep PRODUCT= /sys/bus/usb-serial/devices/ttyUSB0/../uevent
PRODUCT=10c4/ea60/100
```

This means that `ttyUSB0` is assocated to `10c4:ea60` which is the device we are looking for.

Now I will check the associated major and minor number with:

```bash
$ ls -l /dev
...
crw-rw----   1 root  dialout 188,   0 Feb  4 16:00 ttyUSB0
...
```

In my case major `188`, minor `0` for `ttyUSB0`, which is my device `10c4:ea60`. Then proceed to add the major number to your `docker-compose.yml` like outlined above.

## 2. Storage devices

For mounting storage devices such as USBs and external hard drives it is sufficient to **mount `/media` or one of its specific subfolders as a volume**:

```yaml
 9    volumes:
10      - /media:/media
```
