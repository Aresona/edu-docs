# Scheduler

计算节点通过nova-scheduler服务决定怎么调度计算请求。一个计算节点就表示一个运行着nova-compute服务的物理机。

Compute通过下面的配置选项来配置
<pre>
scheduler_driver_task_period = 60
scheduler_driver = nova.scheduler.filter_scheduler.FilterScheduler
scheduler_available_filters = nova.scheduler.filters.all_filters
scheduler_default_filters = RetryFilter, AvailabilityZoneFilter, RamFilter, DiskFilter, ComputeFilter, ComputeCapabilitiesFilter, ImagePropertiesFilter, ServerGroupAntiAffinityFilter, ServerGroupAffinityFilter
</pre>

默认情况下，scheduler_driver被配置成filer_scheduler，在默认配置中，这个调试器需要主机满足下面几个标准：

1. RetryFiler
2. AvailabilityZoneFilter
3. RamFilter
4. DiskFilter
5. ComputeFilter
6. ComputeCapabilitiesFilter
7. ImagePropertiesFilter
8. ServerGroupAntiAffinityFilter
9. ServerGroupAffinityFilter

scheduler缓存它的可用的主机，并且调度器通过scheduler_driver_task_period选项来指定多久列表更新一次.

> 注意： 不要配置 service_down_time比scheduler_driver_task_period更小，否则会出问题。


