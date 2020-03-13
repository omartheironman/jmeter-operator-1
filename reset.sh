#!/usr/bin/env bash
#Script created to launch Jmeter tests directly from the current terminal without accessing the jmeter master pod.
#It requires that you supply the path to the jmx file
#After execution, test script jmx file may be deleted from the pod itself but not locally.
namespace="tqa"

kubectl delete pod -l jmeter_mode=tqa-loadtest-slave -n tqa
kubectl delete pod -l jmeter_mode=tqa-loadtest-jmeter-master -n tqa

master_pod=`kubectl -n $namespace get po | grep jmeter-master | awk '{print $1}'`

jmx="downscale.jmx"
test_name="$(basename "$jmx")"


kubectl -n $namespace cp "$jmx" "$master_pod:/$test_name"
## Echo Starting Jmeter load test
kubectl -n $namespace exec -ti $master_pod -- /bin/bash /load_test "$test_name"