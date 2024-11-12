#!/bin/bash

kubectl get nodes | tail -n +2 | while read -r name status roles age version; do
    if [[ $roles == *"master"* ]]; then
        echo "Configuring master node: $name"
        kubectl taint node "$name" node-role.kubernetes.io/control-plane:NoSchedule
        kubectl taint node "$name" node-role.kubernetes.io/master:NoSchedule
    elif [[ $roles == "<none>" ]]; then
        echo "Configuring worker node: $name"
        kubectl label nodes "$name" node-role.kubernetes.io/worker=true
    fi
done