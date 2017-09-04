# perf

## man 手册

<pre>
NAME
       perf - Performance analysis tools for Linux

SYNOPSIS
       perf [--version] [--help] [OPTIONS] COMMAND [ARGS]

OPTIONS
       --debug
           Setup debug variable (see list below) in value range (0, 10). Use like: --debug verbose # sets verbose = 1 --debug verbose=2 # sets verbose = 2

               List of debug variables allowed to set:
                 verbose          - general debug messages
                 ordered-events   - ordered events object debug messages
                 data-convert     - data convert command debug messages

       --buildid-dir
           Setup buildid cache directory. It has higher priority than buildid.dir config file option.

DESCRIPTION
       Performance counters for Linux are a new kernel-based subsystem that provide a framework for all things performance analysis. It covers hardware level (CPU/PMU,
       Performance Monitoring Unit) features and software features (software counters, tracepoints) as well.
</pre>

## 帮助信息
<pre>
[root@host30 ~]# perf --help

 usage: perf [--version] [--help] [OPTIONS] COMMAND [ARGS]

 The most commonly used perf commands are:
   annotate        Read perf.data (created by perf record) and display annotated(注释) code
   archive         Create archive(档案) with object files with build-ids found in perf.data file
   bench           General framework for benchmark suites
   buildid-cache   Manage build-id cache.
   buildid-list    List the buildids in a perf.data file
   data            Data file related processing
   diff            Read perf.data files and display the differential profile
   evlist          List the event names in a perf.data file
   inject          Filter to augment(增加) the events stream with additional information
   kmem            Tool to trace/measure kernel memory properties
   kvm             Tool to trace/measure kvm guest os
   list            List all symbolic event types
   lock            Analyze lock events
   mem             Profile(概括) memory accesses
   record          Run a command and record its profile into perf.data
   report          Read perf.data (created by perf record) and display the profile
   sched           Tool to trace/measure scheduler properties (latencies)
   script          Read perf.data (created by perf record) and display trace output
   stat            Run a command and gather performance counter statistics
   test            Runs sanity(明智地) tests.
   timechart       Tool to visualize total system behavior during a workload
   top             System profiling tool.
   trace           strace inspired tool
   probe           Define new dynamic tracepoints
</pre>
# 使用案例

<pre>
perf record --call-graph dwarf -F 99 -p 157
</pre>
## 参数分析
<pre>
record          Run a command and record its profile into perf.data

--call-graph
    Setup and enable call-graph (stack chain/backtrace) recording, implies -g.

        Allows specifying "fp" (frame pointer) or "dwarf"
        (DWARF's CFI - Call Frame Information) or "lbr"
        (Hardware Last Branch Record facility) as the method to collect
        the information used to show the call graphs.

        In some systems, where binaries are build with gcc
        --fomit-frame-pointer, using the "fp" method will produce bogus
        call graphs, using "dwarf", if available (perf tools linked to
        the libunwind library) should be used instead.
        Using the "lbr" method doesn't require any compiler options. It
        will produce call graphs from the hardware LBR registers. The
        main limition is that it is only available on new Intel
        platforms, such as Haswell. It can only get user call chain. It
        doesn't work with branch stack sampling at the same time.
-F, --freq=
           Profile at this frequency
-p, --pid=
    Record events on existing process ID (comma separated list).
</pre>
