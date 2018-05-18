# Networking Overview
## Overview
This topic defines some basic Docker networking concepts and prepares you to design and deploy your applications to take full advantage of these capabilities.

## Network drivers
Docker’s networking subsystem is pluggable, using drivers. Several drivers exist by default, and provide core networking functionality:

* bridge: The default network driver. If you don’t specify a driver, this is the type of network you are creating. Bridge networks are usually used when your applications run in standalone containers that need to communicate. See bridge networks.
* host: For standalone containers, remove network isolation between the container and the Docker host, and use the host’s networking directly. host is only available for swarm services on Docker 17.06 and higher. See use the host network.
* overlay: Overlay networks connect multiple Docker daemons together and enable swarm services to communicate with each other. You can also use overlay networks to facilitate communication between a swarm service and a standalone container, or between two standalone containers on different Docker daemons. This strategy removes the need to do OS-level routing between these containers. See overlay networks.
* macvlan: Macvlan networks allow you to assign a MAC address to a container, making it appear as a physical device on your network. The Docker daemon routes traffic to containers by their MAC addresses. Using the macvlan driver is sometimes the best choice when dealing with legacy applications that expect to be directly connected to the physical network, rather than routed through the Docker host’s network stack. See Macvlan networks.
* none: For this container, disable all networking. Usually used in conjunction with a custom network driver. none is not available for swarm services. See disable container networking.
* Network plugins: You can install and use third-party network plugins with Docker. These plugins are available from Docker Store or from third-party vendors. See the vendor’s documentation for installing and using a given network plugin.

<pre>
[root@docker ~]# docker run  -dit --name test  binbi2357/get-started:part2  bash
aed5c38355970e1b6038350cf2983f9621bae3fa40ac13ea411cb54066a9c06d
[root@docker ~]# docker attach aed5c38355970e1
root@aed5c3835597:/app# 
</pre>
> 在执行完第二条命令后需要加入 `ctrl+a`或`ctrl+i` 才能进行容器，可能还有其他，这里没搞懂；另外退出时可以使用`ctrl+pq`.

## Networking tutorials
### Networking with standalone containers(Bridge Network tutorial)
#### Use the default bridge network 
#### Use user-defined bridge networks
创建四个容器，两个连接到自定义网络`alpine-net`,一个连接到*bridge*网络，最后一个连接到两个网络
<pre>
docker network create --driver bridge alpine-net
docker network ls
docker network inspect alpine-net
docker run -dit --name alpine1 --network alpine-net alpine ash
docker run -dit --name alpine2 --network alpine-net alpine ash
docker run -dit --name alpine3 alpine ash
docker run -dit --name alpine4 --network alpine-net alpine ash
docker network connect bridge alpine4
</pre>
> 连接到自定义网络的容器，不仅可以通过IP来通信，也可以通过容器名来通信，这个能力叫做自动服务发现。

结论：

1. alpine4可以通过名称和IP ping通alpine-net的所有机器，但是只能通过ip地址ping通alpine3。
2. 这两种bridge网络都可以ping通外网。

### Host networking tutorial
#### Goal
创建一个nginx容器，使其提供80服务，使得从网络方面来看，它是部署在鹤宿主机上的，但其他方面，如存储，进程空间，服务空间是与主机隔离的。
> host网络只在linux上支持

<pre>
docker run --rm -dit --network host --name my_nginx nginx
ip addr show
netstat -lntup|grep 80
</pre>
> 可以看到宿主机并没有创建新的网络接口，并且是docker daemon占用了80端口。

### Overlay Netwokring tutorial
#### Use the default overlay network
此实验需要三个节点的swarm集群，具体操作如下：

***master***
<pre>
docker swarm init --advertise-addr=&lt;IP-ADDRESS-OF-MANAGER>
docker node ls
docker node ls --filter role=manager
docker node ls --filter role=worker
</pre>
* 列出所有网络
<pre>
docker network ls</pre>
可以发现所有节点都有一个叫做`ingress`的overlay网络和一个叫做`docker_gwbridge`的bridge网络。`docker_gwbridge`把`ingress`网络和主机网络连接到一起，以便流量能够在workers和manager之间通信。
***worker***
<pre>
docker swarm --join --token &lt;TOKEN> \
  --advertise-addr &lt;IP-ADDRESS-OF-WORKER-2> \
  &lt;IP-ADDRESS-OF-MANAGER>:2377
</pre>

**service**
<pre>
docker network create -d overlay nginx-net
</pre>
> 只在manager创建就可以了，其他节点会在需要的时候自动创建。



#### Use user-defined overlay network

#### Use an overlay network for standalone containers

#### Communicate between a container and a swarm service




