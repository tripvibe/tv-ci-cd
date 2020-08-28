#!/bin/bash

tkn -n labs-ci-cd pr delete -f -n labs-ci-cd --keep 10
tkn -n labs-ci-cd tr delete -f -n labs-ci-cd --keep 20
oc get pods --all-namespaces | grep Error | awk '{system("oc delete pod " $2  " -n " $1)}'
oc -n labs-ci-cd get pods | grep Completed | awk '{print $1}' | xargs oc -n labs-ci-cd delete pod


