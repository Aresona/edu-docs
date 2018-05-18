# Storage overview
## Manage data in docker
默认容器里所有的文件是存储在 `writable container layer`。这意味着，这部分数据与主机紧密相连，并且在写入的时候需要storage driver来管理文件系统，所以性能没有 `data volume`(直接写入主机文件系统)好。

Docker可以通过两种方式来把数据永久存储在宿主机上：volumes, and bind mounts.如果是运行在linux上也可以使用*tmpfs mount*
## Choose right type of mount
![](https://docs.docker.com/storage/images/types-of-mounts.png)

* ***Volumes*** are stored in a part of the host filesystem which is managed by Docker (/var/lib/docker/volumes/ on Linux). Non-Docker processes should not modify this part of the filesystem. Volumes are the best way to persist data in Docker.
* ***Bind mounts*** may be stored anywhere on the host system. They may even be important system files or directories. Non-Docker processes on the Docker host or a Docker container can modify them at any time.
* ***tmpfs mounts*** are stored in the host system’s memory only, and are never written to the host system’s filesystem.

## More Detail 
### volumes
可以通过下面命令创建一个docker的卷，另外在创建容器或服务时也可以创建卷。该卷存在于宿主机的一个目录里。
<pre>
docker volume create
</pre>
卷可以同时被多个容器挂载，当没有容器在使用时，卷不会自动删除，可以通过命令 `docker volume prune`来删除没用的卷。
### Bind mounts
bind方式与volumes很像，在bind时不需要该文件在主机上存在，它会自己创建，bind方式性能很好，但是有风险，它支持在容器里面修改挂载路径，所以有安全隐患。
### tmpfs mounts
tmpfs是把数据直接保存在内存中，不会永久存在。一般用来存储敏感的信息。

## Good use
### volumes
* 同时在多个容器使用同一个卷，一般卷会在第一个容器使用它时创建，然后可以被多个容器同时可读和读写。
* 可以剥离主机与容器路径
* 可以很好的支持备份，迁移，恢复(/var/lib/docker/volumes/<volume-name>)

### bind mounts
一般情况下最好使用volumes,但下面几种场景适合使用bind mount

* 分享配置文件，如默认 `/etc/resolv.conf`就属于这一类。
* 程序源码，每次修改完代码后可直接通过docker来运行。

### tmpfs
当您不希望数据在主机上或容器内持久存储时，tmpfs挂载最适合使用。 这可能出于安全原因，或者在应用程序需要编写大量非持久状态数据时保护容器的性能。

### Tips
* 如果挂载一个主机上的空目录到容器里面的非空目录时，容器里的数据会拷贝到主机目录。
* 当主机目录与容器目录都有数据时，挂载后只能访问主机的数据，就像我们平时挂载U盘一样。

# Volumes
volumes are often a better choice than persisting data in a container’s writable layer, because using a volume does not increase the size of containers using it, and the volume’s contents exist outside the lifecycle of a given container.
![](https://docs.docker.com/storage/images/types-of-mounts-volume.png)

## -v or --mount
早期，-v用来为容器挂载卷，而 --mount 用来为swarm挂载卷。新版本中，可以统一使用mount,--mount把所有选项分离。

--mount的几个选项:

* type: bind,volume,tmpfs
* source: named volumes,omitted(anaonymous volume)
* destination: path
* readonly: present or non
* volume-opt: 可以被指定超过一次。

<pre>
$ docker service create \
     --mount 'type=volume,src=<VOLUME-NAME>,dst=<CONTAINER-PATH>,volume-driver=local,volume-opt=type=nfs,volume-opt=device=<nfs-server>:<nfs-path>,"volume-opt=o=addr=<nfs-address>,vers=4,soft,timeo=180,bg,tcp,rw"'
    --name myservice \
    <IMAGE>
</pre>

## 卷管理常用命令
<pre>
docker volume create my-vol
docker volume ls
docker volume inspect my-vol
docker volume rm my-vol
$ docker run -d \
  --name devtest \
  --mount source=myvol2,target=/app \
  nginx:latest
docker volume inspect devtest
docker container stop devtest
docker container rm devtest
docker volume rm mylovl2
</pre>
### for service
<pre>
$ docker service create -d \
  --replicas=4 \
  --name devtest-service \
  --mount source=myvol2,target=/app \
  nginx:latest
$ docker service ps devtest-service

ID                  NAME                IMAGE               NODE                DESIRED STATE       CURRENT STATE            ERROR               PORTS
4d7oz1j85wwn        devtest-service.1   nginx:latest        moby                Running             Running 14 seconds ago   
$ docker service rm devtest-service
</pre>
如果使用 local driver,每一个task都创建一个本地的volume,但一些其他的driver可能会支持共享，如AWS,Azure等。可以通过 `docker volume create --driver `或 `docker run --volume-driver`来指定driver。

# Bind mounts
## -v or --mount
早期，-v用来为容器挂载卷，而 --mount 用来为swarm挂载卷。新版本中，可以统一使用mount,--mount把所有选项分离。

--mount的几个选项:

* type: bind,volume,tmpfs
* source: path
* destination: path
* readonly: present or non
* bind-propagation: rprivate,private,rshared,shared,rslave,slave
* consistency: consistent,delegated,cached;这个选项只存在于MAC

<pre>
$ docker run -d \
  -it \
  --name devtest \
  --mount type=bind,source="$(pwd)"/target,target=/app \
  nginx:latest

"Mounts": [
    {
        "Type": "bind",
        "Source": "/tmp/source/target",
        "Destination": "/app",
        "Mode": "",
        "RW": true,
        "Propagation": "rprivate"
    }
],
</pre>
# tmpfs mounts
* Unlike volumes and bind mounts, you can’t share tmpfs mounts between containers.
* This functionality is only available if you’re running Docker on Linux.

## --tmpfs or --mount

--mount:

* type: bind,volume,tmpfs
* destination: path
* tmpfs-type: 

<pre>
$ docker run -d \
  -it \
  --name tmptest \
  --mount type=tmpfs,destination=/app \
  nginx:latest

"Tmpfs": {
    "/app": ""
},
</pre>

option|description
---|---
tmpfs-size|	Size of the tmpfs mount in bytes. Unlimited by default.
tmpfs-mode|	File mode of the tmpfs in octal. For instance, 700 or 0770. Defaults to 1777 or world-writable.

# Storage Driver
## Abount storage driver
Storage drivers allow you to create data in the writable layer of your container. The files won’t be persisted after the container stops, and both read and write speeds are low.
### Images and layers
A Docker image is built up from a series of layers. Each layer represents an instruction in the image’s Dockerfile. Each layer except the very last one is read-only. 
### Container and layers
The major difference between a container and an image is the top writable layer. All writes to the container that add new or modify existing data are stored in this writable layer. When the container is deleted, the writable layer is also deleted. The underlying image remains unchanged.

Because each container has its own writable container layer, and all changes are stored in this container layer, multiple containers can share access to the same underlying image and yet have their own data state. 
![](https://docs.docker.com/storage/storagedriver/images/sharing-layers.jpg)

Docker uses storage drivers to manage the contents of the image layers and the writable container layer. Each storage driver handles the implementation differently, but all drivers use stackable image layers and the copy-on-write (CoW) strategy.
### Container size on disk
To view the approximate size of a running container, you can use the docker ps -s command. Two different columns relate to size.

* size: the amount of data (on disk) that is used for the writable layer of each container
* virtual size: the amount of data used for the read-only image data used by the container plus the container’s writable layer size. Multiple containers may share some or all read-only image data. Two containers started from the same image share 100% of the read-only data, while two containers with different images which have layers in common share those common layers. Therefore, you can’t just total the virtual sizes. This over-estimates the total disk usage by a potentially non-trivial amount.

> 这个数字不包括内存数据(如果swapping是开启状态)

### COW Strategy
Copy-on-write is a strategy of sharing and copying files for maximum efficiency. If a file or directory exists in a lower layer within the image, and another layer (including the writable layer) needs read access to it, it just uses the existing file. The first time another layer needs to modify the file (when building the image or running the container), the file is copied into that layer and modified. 

每一层的数据都存储在 `/var/lib/dokcer/storage-driver/layers/`下,如`/var/lib/docker/aufs/layers/xxxxx`

<pre>
docker history image-id
</pre>
可以看到镜像的所有层，同一driver下，相同的层是共享的，在目录中只保存一次。

### Copying makes containers efficient
When you start a container, a thin writable container layer is added on top of the other layers. Any changes the container makes to the filesystem are stored here. Any files the container does not change do not get copied to this writable layer. This means that the writable layer is as small as possible.

When an existing file in a container is modified, the storage driver performs a copy-on-write operation. The specifics steps involved depend on the specific storage driver. For the default aufs driver and the overlay and overlay2 drivers, the copy-on-write operation follows this rough sequence:

* Search through the image layers for the file to update. The process starts at the newest layer and works down to the base layer one layer at a time. When results are found, they are added to a cache to speed future operations.
* Perform a copy_up operation on the first copy of the file that is found, to copy the file to the container’s writable layer.
* Any modifications are made to this copy of the file, and the container cannot see the read-only copy of the file that exists in the lower layer.

每启动一个容器，其实就是启动一个writable layer,所以复制也会加快容器启动的速度。

## Select a storage driver
### Docker storage drivers
to choose the best storage driver for your workloads. In making this decision, there are three high-level factors to consider:

* If multiple storage drivers are supported in your kernel, Docker has a prioritized list of which storage driver to use if no storage driver is explicitly configured, assuming that the prerequisites for that storage driver are met:
	* If possible, the storage driver with the least amount of configuration is used, such as btrfs or zfs. Each of these relies on the backing filesystem being configured correctly.
	* Otherwise, try to use the storage driver with the best overall performance and stability in the most usual scenarios.
		* overlay2 is preferred, followed by overlay. Neither of these requires extra configuration. overlay2 is the default choice for Docker CE.
		* devicemapper is next, but requires direct-lvm for production environments, because loopback-lvm, while zero-configuration, has very poor performance.

    The selection order is defined in Docker’s source code. You can see the order by looking at the source code for Docker CE 18.03 You can use the branch selector at the top of the file viewer to choose a different branch, if you run a different version of Docker.
* Your choice may be limited by your Docker edition, operating system, and distribution. For instance, aufs is only supported on Ubuntu and Debian, and may require extra packages to be installed, while btrfs is only supported on SLES, which is only supported with Docker EE. See Support storage drivers per Linux distribution.
* Some storage drivers require you to use a specific format for the backing filesystem. If you have external requirements to use a specific backing filesystem, this may limit your choices. See Supported backing filesystems.
* After you have narrowed down which storage drivers you can choose from, your choice are determined by the characteristics of your workload and the level of stability you need. See Other considerations for help making the final decision.

**推荐**

Linux distribution| Recommended storage drivers
---|---
centos|devicemapper vfs
ubuntu| aufs devicemapper overlay2 overlay zfs vfs
detian| aufs devicemapper overlay2 overlay vfs
Docker CE on Fedora	|devicemapper, overlay2 (Fedora 26 or later, experimental), overlay (experimental), vfs

When possible, overlay2 is the recommended storage driver. When installing Docker for the first time, overlay2 is used by default. 

> 最佳实践:When in doubt, the best all-around configuration is to use a modern Linux distribution with a kernel that supports the overlay2 storage driver, and to use Docker volumes for write-heavy workloads instead of relying on writing data to the container’s writable layer.

### Supported backing filesystems
With regard to Docker, the backing filesystem is the filesystem where /var/lib/docker/ is located. Some storage drivers only work with specific backing filesystems.

Storage driver|	Supported backing filesystems
---|---
overlay, overlay2	|ext4, xfs
aufs|	ext4, xfs
devicemapper	|direct-lvm
btrfs|	btrfs
zfs|	zfs

### Suitability for your workload
Among other things, each storage driver has its own performance characteristics that make it more or less suitable for different workloads. Consider the following generalizations:

* aufs, overlay, and overlay2 all operate at the file level rather than the block level. This uses memory more efficiently, but the container’s writable layer may grow quite large in write-heavy workloads.
* Block-level storage drivers such as devicemapper, btrfs, and zfs perform better for write-heavy workloads (though not as well as Docker volumes).
* For lots of small writes or containers with many layers or deep filesystems, overlay may perform better than overlay2.
* btrfs and zfs require a lot of memory.
* zfs is a good choice for high-density workloads such as PaaS.

> 通过 `docker info`可以查看当前的storage driver


## Use the AUFS storage driver
* Use the following command to verify that your kernel supports AUFS.
<pre>
$ grep aufs /proc/filesystems
nodev   aufs
</pre>
* Check with storage driver Docker is using.
<pre>
docker info|grep Storage
</pre>
## Use the Device Mapper storage driver
`devicemapper`利用内核的`Device Mapper`的thin-provisioning和快照功能来实现镜像层的容器层的管理。

The devicemapper driver uses block devices dedicated to Docker and operates at the block level, rather than the file level. These devices can be extended by adding physical storage to your Docker host, and they perform better than using a filesystem at the level of the operating system.

### Configure loop-lvm mode for testing
*  Stop Docker.
<pre>
$ sudo systemctl stop docker
</pre>
* Edit /etc/docker/daemon.json. If it does not yet exist, create it. Assuming that the file was empty, add the following contents.
<pre>
{
  "storage-driver": "devicemapper"
}
</pre>

Docker does not start if the daemon.json file contains badly-formed JSON.

*Start Docker.
<Pre>
$ sudo systemctl start docker
</pre>
* Verify that the daemon is using the devicemapper storage driver. Use the docker info command and look for Storage Driver.
<pre>
$ docker info

  Containers: 0
    Running: 0
    Paused: 0
    Stopped: 0
  Images: 0
  Server Version: 17.03.1-ce
  Storage Driver: devicemapper
  Pool Name: docker-202:1-8413957-pool
  Pool Blocksize: 65.54 kB
  Base Device Size: 10.74 GB
  Backing Filesystem: xfs
  Data file: /dev/loop0
  Metadata file: /dev/loop1
  Data Space Used: 11.8 MB
  Data Space Total: 107.4 GB
  Data Space Available: 7.44 GB
  Metadata Space Used: 581.6 kB
  Metadata Space Total: 2.147 GB
  Metadata Space Available: 2.147 GB
  Thin Pool Minimum Free Space: 10.74 GB
  Udev Sync Supported: true
  Deferred Removal Enabled: false
  Deferred Deletion Enabled: false
  Deferred Deleted Device Count: 0
  Data loop file: /var/lib/docker/devicemapper/data
  Metadata loop file: /var/lib/docker/devicemapper/metadata
  Library Version: 1.02.135-RHEL7 (2016-11-16)
<output truncated>
</pre>
This host is running in loop-lvm mode, which is not supported on production systems. This is indicated by the fact that the Data loop file and a Metadata loop file are on files under /var/lib/docker/devicemapper. These are loopback-mounted sparse files. For production systems, see Configure direct-lvm mode for production.

### Configure direct-lvm mode for production
Production hosts using the devicemapper storage driver must use direct-lvm mode. This mode uses block devices to create the thin pool. This is faster than using loopback devices, uses system resources more efficiently, and block devices can grow as needed. However, more set-up is required than loop-lvm mode.

**CONFIGURE DIRECT-LVM MODE MANUALLY**
The procedure below creates a logical volume configured as a thin pool to use as backing for the storage pool. It assumes that you have a spare block device at /dev/xvdf with enough free space to complete the task. The device identifier and volume sizes may be different in your environment and you should substitute your own values throughout the procedure. The procedure also assumes that the Docker daemon is in the stopped state.

* Identify the block device you want to use. The device is located under /dev/ (such as /dev/xvdf) and needs enough free space to store the images and container layers for the workloads that host runs. A solid state drive is ideal.
* Stop Docker
<pre>
systemctl stop docker
</pre>
* Install the following packages:
	* RHEL / CentOS: device-mapper-persistent-data, lvm2, and all dependencies
	* Ubuntu / Debian: thin-provisioning-tools, lvm2, and all dependencies

* Create a physical volume on your block device from step 1, using the pvcreate command. Substitute your device name for /dev/xvdf.

> Warning: The next few steps are destructive, so be sure that you have specified the correct device!
> 
<pre>
$ sudo pvcreate /dev/xvdf
Physical volume "/dev/xvdf" successfully created.
</pre>
* Create a docker volume group on the same device, using the vgcreate command.
<pre>
vgcreate docker /dev/xvdf
</pre>
* Create two logical volumes named thinpool and thinpoolmeta using the lvcreate command. The last parameter specifies the amount of free space to allow for automatic expanding of the data or metadata if space runs low, as a temporary stop-gap. These are the recommended values.

<pre>
$ sudo lvcreate --wipesignatures y -n thinpool docker -l 95%VG
Logical volume "thinpool" created.
$ sudo lvcreate --wipesignatures y -n thinpoolmeta docker -l 1%VG
Logical volume "thinpoolmeta" created.</pre>
* Convert the volumes to a thin pool and a storage location for metadata for the thin pool, using the lvconvert command.

<pre>
$ sudo lvconvert -y \
--zero n \
-c 512K \
--thinpool docker/thinpool \
--poolmetadata docker/thinpoolmeta

WARNING: Converting logical volume docker/thinpool and docker/thinpoolmeta to
thin pool's data and metadata volumes with metadata wiping.
THIS WILL DESTROY CONTENT OF LOGICAL VOLUME (filesystem etc.)
Converted docker/thinpool to thin pool.
</pre>
* Configure autoextension of thin pools via an lvm profile.
<pre>
$ sudo vi /etc/lvm/profile/docker-thinpool.profile
</pre>
* Specify thin_pool_autoextend_threshold and thin_pool_autoextend_percent values.

thin_pool_autoextend_threshold is the percentage of space used before lvm attempts to autoextend the available space (100 = disabled, not recommended).

thin_pool_autoextend_percent is the amount of space to add to the device when automatically extending (0 = disabled).

The example below adds 20% more capacity when the disk usage reaches 80%.
<pre>
activation {
  thin_pool_autoextend_threshold=80
  thin_pool_autoextend_percent=20
}
</pre>
Save the file.

[.....](https://docs.docker.com/storage/storagedriver/device-mapper-driver/#configure-direct-lvm-mode-for-production)
