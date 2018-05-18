# Thin-Provisioning
In computing, thin provisioning involves using virtualization technology to give the appearance of having more physical resources than are actually available. If a system always has enough resource to simultaneously support all of the virtualized resources, then it is not thin provisioned. The term thin provisioning is applied to disk layer in this article, but could refer to an allocation scheme for any resource. For example, real memory in a computer is typically thin-provisioned to running tasks with some form of address translation technology doing the virtualization. Each task acts as if it has real memory allocated. The sum of the allocated virtual memory assigned to tasks typically exceeds the total of real memory.


The efficiency of thin or thick/fat provisioning is a function of the use case, not of the technology. Thick provisioning is typically more efficient when the amount of resource used very closely approximates to the amount of resource allocated. Thin provisioning offers more efficiency where the amount of resource used is much smaller than allocated, so that the benefit of providing only the resource needed exceeds the cost of the virtualization technology used.

> Over-allocation or over-subscription is a mechanism that allows a server to view more storage capacity than has been physically reserved on the storage array itself. Thin provisioning enables over-allocation or over-subscription.
## 精简置备
自动精简配置，有时也被称为”超额申请“，是一中重要的新兴存储技术。本文定义了自动精简配置，并介绍它的工作原理、使用局限和一些使用建议。

如果应用程序所使用的存储空间已满，就会崩溃。因此，存储管理员通常分配比应用程序实际需要的存储空间更大的存储容量，以避免任何潜在的应用程序故障。这种做法为未来的增长提供了“headroom”（净空），并减少了应用程序出故障的风险。但却需要比实际更多的物理磁盘容量，造成浪费。

在大多数实现，自动精简配置以“从一个普通的存储池中按需提供存储给应用程序”作为基本原则。自动精简配置可与存储虚拟化一起组合工作，这基本上是有效地利用该技术的前提条件。有了自动精简配置，存储管理员就可以像往常一样分配逻辑存储（600G）给应用程序，但仅在需要时才真正占用物理容量。当该存储的利用率接近预定阈值时（例如90％） ，该阵列会自动从虚拟存储池中分配空间来扩展该卷，而不需要存储管理员的人工干预。卷可以往常一样超额分配（over allocated ），因此应用程序认为它有充足的存储空间，但实际上并没有浪费存储空间。自动精简配置是一种按需存储技术，基本上消除了已分配但未使用的空间的浪费。
## 对比
虚拟磁盘有3种格式：(1)thin provision (2)thick(也叫zeroedthick) (3)eagerzeroedthik 

(1) thin provision就是一种按需分配的格式，创建时虚拟磁盘不会分配给所有需要的空间，而是根据需要，vmdk自动增大并一边zero一边使用这些新空间；vmdk文件的真实大小不等于创建的虚拟磁盘的大小，而只是等于实际数据的大小。(zero就是对磁盘空白处写入0，可以理解成或者翻译成初始化)。![](http://blog.51cto.com/attachment/201002/201002231266940027002.gif)
 
(2) zeroedthick格式，在创建时分配给所有空间，vmdk文件大小等于创建的虚拟磁盘大小，虚拟磁盘中的空闲空间被预占，但空闲空间(empty space)并没有zeroed，需要在使用的时候再zero。由于磁盘在第一次写入时必须zero，这个类型的磁盘在第一次磁盘块写入时会有轻微的I/O性能损失。 ![](http://blog.51cto.com/attachment/201002/201002231266940051791.gif)
 
(3) eagerzeroedthick，在创建时分配给所有空间，vmdk文件大小等于创建的虚拟磁盘大小，虚拟磁盘中的空闲空间被预占。另外，在创建磁盘时，会将所有数据块都初始化(zero)，这将花费更多时间。这种格式的磁盘因为已经zero化，使用时不再需要zero，因此第一次写入数据到磁盘块时的性能较好。启用FT必须使用eagerzeoedthick格式的虚拟磁盘(如果原先不是，也会被转换成这种格式) ![](http://blog.51cto.com/attachment/201002/201002231266940084192.gif)
 

举例来说，1个500GB的虚拟磁盘，其中100GB已用，还有400GB未用空间。thin格式的vmdk文件大小就是100GB，zeroedthick和eagerzeroedthick格式的vmdk文件大小都是500GB，只不过eagerzeroedthick的那400GB未用空间都已经初始化过了，都填上了0，而zeroedthick的那400GB未用空间还没初始化。