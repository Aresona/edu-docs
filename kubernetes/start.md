# 安装Minikube
***Minikube***: A tool for running Kubernetes locally.
Minikube runs a single-node cluster inside a VM on your computer.

* Install docker

<pre>

</pre>

## Kubernetes Basics Modules
### Using Manikube to Create a Cluster
### Using kubectl to create a Deployment
#### Kubernetes Clusters
A Kubernetes cluster consists of two types of resources:

* The **Master** coordinates the cluster
* **Nodes** are the workers that run applications

#### Kubernetes Deployments
Once you have a running Kubernetes cluster, you can deploy your containerized applications on top of it. To do so, you create a Kubernetes Deployment configuration. The Deployment instructs Kubernetes how to create and update instances of your application.

Once the application instances are created, a Kubernetes Deployment Controller continuously monitors those instances. If the Node hosting an instance goes down or is deleted, the Deployment controller replaces it. This provides **a self-healing mechanism to address machine failure or maintenance**.

#### execute
<pre>
kubectl version
kubectl cluster-info
kubectl cluster-info dump
kubectl get nodes
kubectl run kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --port=8080
$ kubectl get deployments
export POD_NAME=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
echo Name of the Pod: $POD_NAME
curl http://localhost:8001/api/v1/namespaces/default/pods/$POD_NAME/proxy/

</pre>

* The Master is responsible for managing the cluster. 
* A node is a VM or a physical computer that serves as a worker machine in a Kubernetes cluster. 
* The nodes communicate with the master using the Kubernetes API, which the master exposes. End users can also use the Kubernetes API directly to interact with the cluster.
> The API server will automatically create an endpoint for each pod, based on the pod name, that is also accessible through the proxy.


###　Viewing Pods and Nodes

#### Kubernetes Pods

创建 deployment 时，kubernetes会创建一个pod来运行应用实例，Pod代表一组应用容器和它们共享的一些资源，包括：

* Shared storage,as Volumes
* Networking, as a unique cluster IP address
* Information about how to run each container,suach as the container image version or specific ports to use

Pod用于模拟特定于应用程序的“逻辑主机”，并且可以包含相对紧密耦合的不同应用程序容器。 例如，一个Pod可能包含带有Node.js应用程序的容器，以及一个提供Node.js Web服务器发布的数据的不同容器。 Pod中的容器共享一个IP地址和端口空间，它们总是共同定位(co-locaetd)并共同调度(co-scheduled)，并在同一个节点上的共享上下文中运行。

`Pod` 是Kubernetes平台上的原子单元。 当我们在 `Kubernetes` 上创建一个部署时，该部署将创建带有容器的Pod（而不是直接创建容器）。 每个Pod都与其调度的节点绑定，并保持在该位置直到终止（根据重新启动策略）或删除。 在节点故障的情况下，将会在其他的节点上重新调度该pod。

#### Nodes
每个kubenetes node最少包括:

* Kubelet进程，负责master与node之间的交流，管理节点上运行的pod或container
* A container runtime(like Docker,rkt),负责拉取镜像，启动容器，运行应用。

> Containers should only be scheduled together in a single Pod if they are tightly coupled and need to share resources such as disk.

<pre>
kubectl get - list resources
kubectl describe - show detailed information about a resource
kubectl logs - print the logs from a container in a pod
kubectl exec - execute a command on a container in a pod
</pre>
You can use these commands to see when applications were deployed, what their current statuses are, where they are running and what their configurations are.
#### execute
<pre>
$ kubectl get pods
NAME                                   READY     STATUS              RESTARTS   AGE
kubernetes-bootcamp-5c69669756-n4969   0/1       ContainerCreating   0          11s
$ kubectl describe pods
Name:           kubernetes-bootcamp-5c69669756-n4969
Namespace:      default
Node:           minikube/172.17.0.127
Start Time:     Mon, 21 May 2018 10:55:03 +0000
Labels:         pod-template-hash=1725225312
                run=kubernetes-bootcamp
Annotations:    <none>
Status:         Running
IP:             172.18.0.2
Controlled By:  ReplicaSet/kubernetes-bootcamp-5c69669756
Containers:
  kubernetes-bootcamp:
    Container ID:   docker://0d365b48ccf5a55c5562352ac7868d3982894f429b9f2b65106ba8ac9a19d209
    Image:          gcr.io/google-samples/kubernetes-bootcamp:v1
    Image ID:       docker-pullable://gcr.io/google-samples/kubernetes-bootcamp@sha256:0d6b8ee63bb57c5f5b6156f446b3bc3b3c143d233037f3a2f00e279c8fcc64af
    Port:           8080/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Mon, 21 May 2018 10:55:14 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-rngx8 (ro)
Conditions:
  Type           Status
  Initialized    True
  Ready          True
  PodScheduled   True
Volumes:
  default-token-rngx8:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-rngx8
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason                 Age   From               Message
  ----    ------                 ----  ----               -------
  Normal  Scheduled              32s   default-scheduler  Successfully assigned kubernetes-bootcamp-5c69669756-n4969 to minikube
  Normal  SuccessfulMountVolume  32s   kubelet, minikube  MountVolume.SetUp succeeded for volume "default-token-rngx8"
  Normal  Pulled                 23s   kubelet, minikube  Container image "gcr.io/google-samples/kubernetes-bootcamp:v1" already present on machine
  Normal  Created                21s   kubelet, minikube  Created container
  Normal  Started                20s   kubelet, minikube  Started container
$ export POD_NAME=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
$ echo Name of the Pod: $POD_NAME
Name of the Pod: kubernetes-bootcamp-5c69669756-n4969
$ curl http://localhost:8001/api/v1/namespaces/default/pods/$POD_NAME/proxy/
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5c69669756-n4969 | v=1
$ kubectl logs $POD_NAME
Kubernetes Bootcamp App Started At: 2018-05-21T10:55:15.436Z | Running On:  kubernetes-bootcamp-5c69669756-n4969

Running On: kubernetes-bootcamp-5c69669756-n4969 | Total Requests: 1 | App Uptime: 250.72 seconds | Log Time: 2018-05-21T10
:59:26.156Z
</pre>
> 应用发出的任何东西都会发送给标准输出，并作为日志，我们可以通过 `kubectl logs` 命令来查看。这里不需要指定容器名，因为当前pod里只有一个容器。

只要容器是运行着的，我们就可以直接在容器里执行命令。

<pre>
kubectl exec $POD_NAME env  # 列出环境变量
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=kubernetes-bootcamp-5c69669756-n4969
KUBERNETES_SERVICE_PORT=443KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP_PORT=443
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
KUBERNETES_SERVICE_HOST=10.96.0.1
NPM_CONFIG_LOGLEVEL=info
NODE_VERSION=6.3.1
HOME=/root
$ kubectl exec -it $POD_NAME bash # 进入容器
root@kubernetes-bootcamp-5c69669756-n4969:/# cat server.js
var http = require('http');
var requests=0;
var podname= process.env.HOSTNAME;
var startTime;
var host;
var handleRequest = function(request, response) {
  response.setHeader('Content-Type', 'text/plain');
  response.writeHead(200);
  response.write("Hello Kubernetes bootcamp! | Running on: ");
  response.write(host);
  response.end(" | v=1\n");
  console.log("Running On:" ,host, "| Total Requests:", ++requests,"| App Uptime:", (new Date() - startTime)/1000 , "seconds", "| Log Time:",new Date());
}
var www = http.createServer(handleRequest);
www.listen(8080,function () {
    startTime = new Date();;
    host = process.env.HOSTNAME;
    console.log ("Kubernetes Bootcamp App Started At:",startTime, "| Running On: " ,host, "\n" );
});
</pre>

### Using a Service to Expose Your App

#### Overview of Kubernetes Services

在kubernetes中，pod会随着主机宕机而丢失，所以一般我们会有多个副本，但是要保证前端调用，需要有一个统一的接口，来无视后端的变动，这时就需要services这个逻辑层，它用来定义一个逻辑的pod集，并且通过service来访问这些pods。services实现了多个pods间的松耦合，并且services一般通过*LabelSelector*来识别。

虽然每个pod都有一个独立的IP，但是果没有services,这些IP是不会暴漏在外网，service允许应用收到流量，services有多个types.

* ClusterIP(default) - Exposes the Service on an internal IP in the cluster. This type makes the Service only reachable from within the cluster.
* NodePort - Exposes the Service on the same port of each selected Node in the cluster using NAT. Makes a Service accessible from outside the cluster using <NodeIP>:<NodePort>. Superset of ClusterIP.
* LoadBalancer - Creates an external load balancer in the current cloud (if supported) and assigns a fixed, external IP to the Service. Superset of NodePort.
* ExternalName - Exposes the Service using an arbitrary name (specified by externalName in the spec) by returning a CNAME record with the name. No proxy is used. This type requires v1.7 or higher of kube-dns.

> A Kubernetes Service is an abstraction layer which defines a logical set of Pods and enables external traffic exposure, load balancing and service discovery for those Pods.

#### Services and labels
A Service routes traffic across a set of Pods. Services are the abstraction that allow pods to die and replicate in Kubernetes without impacting your application. **Discovery and routing among dependent Pods (such as the frontend and backend components in an application) is handled by Kubernetes Services.**

Services match a set of Pods using labels and selectors, a grouping primitive that allows logical operation on objects in Kubernetes. Labels are key/value pairs attached to objects and can be used in any number of ways:

* Designate objects for development, test, and production
* Embed version tags
* Classify an object using tags

> You can create a Service at the same time you create a Deployment by using
--expose in kubectl.

Lables can be attached to objects at creation time or later on. They can be modified at any time. 
#### execute
<pre>
kubectl get pods
kubectl get services
kubectl expose deployment/kubernetes-bootcamp --type="NodePort" --port 8080  # 创建并暴漏
$ kubectl get services
NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes            ClusterIP   10.96.0.1       <none>        443/TCP          1m
kubernetes-bootcamp   NodePort    10.107.88.243   <none>        8080:31058/TCP   6s
$ kubectl describe services/kubernetes-bootcamp
Name:                     kubernetes-bootcamp
Namespace:                default
Labels:                   run=kubernetes-bootcamp
Annotations:              <none>
Selector:                 run=kubernetes-bootcamp
Type:                     NodePort
IP:                       10.107.88.243
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  31058/TCP
Endpoints:                172.18.0.4:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
$ export NODE_PORT=$(kubectl get services/kubernetes-bootcamp -o go-template='{{(index .spec.ports 0).nodePort}}')
$ echo NODE_PORT=$NODE_PORT
NODE_PORT=31058
$ curl $(minikube ip):$NODE_PORT
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5c69669756-v66gm | v=1
$ kubectl describe deployment
Name:                   kubernetes-bootcamp
Namespace:              default
CreationTimestamp:      Thu, 24 May 2018 08:03:49 +0000
Labels:                 run=kubernetes-bootcamp
Annotations:            deployment.kubernetes.io/revision=1
Selector:               run=kubernetes-bootcamp
Replicas:               1 desired | 1 updated | 1 total | 1 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
$ kubectl describe deployment
Name:                   kubernetes-bootcamp
Namespace:              default
CreationTimestamp:      Thu, 24 May 2018 08:03:49 +0000
Labels:                 run=kubernetes-bootcamp
Annotations:            deployment.kubernetes.io/revision=1
Selector:               run=kubernetes-bootcamp
Replicas:               1 desired | 1 updated | 1 total | 1 availab
le | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  1 max unavailable, 1 max surge
Pod Template:
  Labels:  run=kubernetes-bootcamp
  Containers:
   kubernetes-bootcamp:
    Image:        gcr.io/google-samples/kubernetes-bootcamp:v1
    Port:         8080/TCP    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   kubernetes-bootcamp-5c69669756 (1/1 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  8m    deployment-controller  Scaled up replica set kubernetes-bootcamp-5c69669756 to 1
$ kubectl get pods -l run=kubernetes-bootcamp
kubectl get services -l run=kubernetes-bootcamNAME                  READY     STATUS    RESTARTS   AGE
kubernetes-bootcamp-5c69669756-6dswj   1/1       Running   0   10m
$ kubectl get services -l run=kubernetes-bootcamp
NAME                  TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
kubernetes-bootcamp   NodePort   10.101.8.155   <none>        8080:30249/TCP   8m
$ kubectl label pod $POD_NAME app=v1
pod "kubernetes-bootcamp-5c69669756-6dswj" labeled
$ kubectl describe pods $POD_NAME
Name:           kubernetes-bootcamp-5c69669756-6dswj
Namespace:      default
Node:           minikube/172.17.0.102
Start Time:     Thu, 24 May 2018 08:03:56 +0000
Labels:         app=v1
                pod-template-hash=1725225312
                run=kubernetes-bootcamp
Annotations:    <none>
Status:         Running
IP:             172.18.0.2
Controlled By:  ReplicaSet/kubernetes-bootcamp-5c69669756
Containers:
  kubernetes-bootcamp:
    Container ID:   docker://13b90a839e3f237cd12040bbd999bc22af6bca735b23624dfe411f16666cc556
    Image:          gcr.io/google-samples/kubernetes-bootcamp:v1
    Image ID:       docker-pullable://gcr.io/google-samples/kubernetes-bootcamp@sha256:0d6b8ee63bb57c5f5b6156f446b3bc3b3c143d233037f3a2f00e279c8fcc64af
    Port:           8080/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Thu, 24 May 2018 08:04:32 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-sbdrp (ro)
Conditions:
  Type           Status
  Initialized    True
  Ready          True
  PodScheduled   True
Volumes:
  default-token-sbdrp:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-sbdrp
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason                 Age   From               Message
  ----    ------                 ----  ----               -------
  Normal  Scheduled              11m   default-scheduler  Successfully assigned kubernetes-bootcamp-5c69669756-6dswj to minikube
  Normal  SuccessfulMountVolume  11m   kubelet, minikube  MountVolume.SetUp succeeded for volume "default-token-sbdrp"
  Normal  Pulled                 10m   kubelet, minikube  Container image "gcr.io/google-samples/kubernetes-bootcamp:v1" already present on machine
  Normal  Created                10m   kubelet, minikube  Created container
  Normal  Started                10m   kubelet, minikube  Started container
$
$ kubectl get pods -l app=v1
NAME                                   READY     STATUS    RESTARTS   AGE
kubernetes-bootcamp-5c69669756-6dswj   1/1       Running   0   13m
$ kubectl delete service -l run=kubernetes-bootcamp
$ kubectl get services
$ curl $(minikube ip):$NODE_PORT
$ kubectl exec -it $POD_NAME curl localhost:8080
</pre>

### Running Multiple Instances of Your App

#### Scaling overview

Services will monitor continuously the running Pods using endpoints,to ensure the traffic is sent only to available Pods.


#### Execute

<pre>
kubectl get deployments
$ kubectl get deployments
NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1         1         1            0           4s
$ kubectl get deployments
NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1         1         1            1           24s
$ kubectl scale deployments/kubernetes-bootcamp --replicas=4
deployment.extensions "kubernetes-bootcamp" scaled
$ kubectl get deployments
NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   4         4         4            4           1m
$ kubectl get pods -o wide
NAME                                   READY     STATUS    RESTARTS   AGE       IP           NODE
kubernetes-bootcamp-5c69669756-7r4ww   1/1       Running   0          1m        172.18.0.2   minikube
kubernetes-bootcamp-5c69669756-fmgf8   1/1       Running   0          23s       172.18.0.5   minikube
kubernetes-bootcamp-5c69669756-pfsnb   1/1       Running   0          23s       172.18.0.6   minikube
kubernetes-bootcamp-5c69669756-vgpmc   1/1       Running   0          23s       172.18.0.7   minikube
$ kubectl describe deployments/kubernetes-bootcamp
Name:                   kubernetes-bootcamp
Namespace:              default
CreationTimestamp:      Thu, 24 May 2018 10:24:57 +0000
Labels:                 run=kubernetes-bootcamp
Annotations:            deployment.kubernetes.io/revision=1
Selector:               run=kubernetes-bootcamp
Replicas:               4 desired | 4 updated | 4 total | 4 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  1 max unavailable, 1 max surge
Pod Template:
  Labels:  run=kubernetes-bootcamp
  Containers:
   kubernetes-bootcamp:
    Image:        gcr.io/google-samples/kubernetes-bootcamp:v1
    Port:         8080/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Progressing    True    NewReplicaSetAvailable
  Available      True    MinimumReplicasAvailable
OldReplicaSets:  <none>
NewReplicaSet:   kubernetes-bootcamp-5c69669756 (4/4 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  1m    deployment-controller  Scaled up replica set kubernetes-bootcamp-5c69669756 to 1
  Normal  ScalingReplicaSet  42s   deployment-controller  Scaled up replica set kubernetes-bootcamp-5c69669756 to 4
$ kubectl get pods -o wide
NAME                                   READY     STATUS    RESTARTS   AGE       IP           NODE
kubernetes-bootcamp-5c69669756-7r4ww   1/1       Running   0          1m        172.18.0.2   minikube
kubernetes-bootcamp-5c69669756-fmgf8   1/1       Running   0          23s       172.18.0.5   minikube
kubernetes-bootcamp-5c69669756-pfsnb   1/1       Running   0          23s       172.18.0.6   minikube
kubernetes-bootcamp-5c69669756-vgpmc   1/1       Running   0          23s       172.18.0.7   minikube
$ kubectl describe deployments/kubernetes-bootcamp
Name:                   kubernetes-bootcamp
Namespace:              default
CreationTimestamp:      Thu, 24 May 2018 10:24:57 +0000
Labels:                 run=kubernetes-bootcamp
Annotations:            deployment.kubernetes.io/revision=1
Selector:               run=kubernetes-bootcamp
Replicas:               4 desired | 4 updated | 4 total | 4 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  1 max unavailable, 1 max surge
Pod Template:
  Labels:  run=kubernetes-bootcamp
  Containers:
   kubernetes-bootcamp:
    Image:        gcr.io/google-samples/kubernetes-bootcamp:v1
    Port:         8080/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Progressing    True    NewReplicaSetAvailable
  Available      True    MinimumReplicasAvailable
OldReplicaSets:  <none>
NewReplicaSet:   kubernetes-bootcamp-5c69669756 (4/4 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  1m    deployment-controller  Scaled up replica set kubernetes-bootcamp-5c69669756 to 1
  Normal  ScalingReplicaSet  42s   deployment-controller  Scaled up replica set kubernetes-bootcamp-5c69669756 to 4
$ kubectl get services
NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes            ClusterIP   10.96.0.1       <none>        443/TCP          3m
kubernetes-bootcamp   NodePort    10.99.249.152   <none>        8080:30462/TCP   2m
$ kubectl describe services/kubernetes-bootcamp
Name:                     kubernetes-bootcamp
Namespace:                default
Labels:                   run=kubernetes-bootcamp
Annotations:              <none>
Selector:                 run=kubernetes-bootcamp
Type:                     NodePort
IP:                       10.99.249.152
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  30462/TCP
Endpoints:                172.18.0.2:8080,172.18.0.5:8080,172.18.0.6:8080 + 1 more...
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
$ export NODE_PORT=$(kubectl get services/kubernetes-bootcamp -o go-template='{{(index .spec.ports 0).nodePort}}')
$ echo NODE_PORT=$NODE_PORT
NODE_PORT=30462
$ curl $(minikube ip):$NODE_PORT
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5c69669756-fmgf8 | v=1
$ curl $(minikube ip):$NODE_PORT
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5c69669756-7r4ww | v=1
$ curl $(minikube ip):$NODE_PORT
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5c69669756-fmgf8 | v=1
$ curl $(minikube ip):$NODE_PORT
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5c69669756-pfsnb | v=1
$ curl $(minikube ip):$NODE_PORT
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5c69669756-pfsnb | v=1
$ kubectl scale deployments/kubernetes-bootcamp --replicas=2
deployment.extensions "kubernetes-bootcamp" scaled
$ kubectl get deployments
NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   2         2         2            2           4m
$ kubectl get pods -o wide
NAME                                   READY     STATUS        RESTARTS   AGE       IP           NODE
kubernetes-bootcamp-5c69669756-7r4ww   1/1       Running       0          4m        172.18.0.2   minikube
kubernetes-bootcamp-5c69669756-fmgf8   1/1       Terminating   0          3m        172.18.0.5   minikube
kubernetes-bootcamp-5c69669756-pfsnb   1/1       Terminating   0          3m        172.18.0.6   minikube
kubernetes-bootcamp-5c69669756-vgpmc   1/1       Running       0          3m        172.18.0.7   minikube
</pre>

### Performing a Rolling Update
