#!/bin/bash
NUM=`egrep -c '(vmx|svm)' /proc/cpuinfo`

[ $NUM -eq 0 ] && exit 1 || exit 0
