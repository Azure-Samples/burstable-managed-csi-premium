#!/bin/bash

# Variables
namespace="burstable-csi"
persistentVolumeClaimTemplate="pvc.yml"
persistentVolumeClaimName="burstable-managed-csi-premium"
storageClassName="burstable-managed-csi-premium"
podTemplate="pod.yml"
podName="nginx"

# Create the namespace if it doesn't already exists in the cluster
result=$(kubectl get namespace -o jsonpath="{.items[?(@.metadata.name=='$namespace')].metadata.name}")

if [[ -n $result ]]; then
    echo "[$namespace] namespace already exists in the cluster"
else
    echo "[$namespace] namespace does not exist in the cluster"
    echo "creating [$namespace] namespace in the cluster..."
    kubectl create namespace $namespace
fi

# Check if the persistent volume claim already exists
result=$(kubectl get pvc -n $namespace -o json | jq -r '.items[].metadata.name | select(. == "'$persistentVolumeClaimName'")')

if [[ -n $result ]]; then
    echo "[$persistentVolumeClaimName] persistent volume claim already exists"
    exit
else
    # Create the persistent volume claim 
    echo "[$persistentVolumeClaimName] persistent volume claim does not exist"
    echo "Creating [$persistentVolumeClaimName] persistent volume claim..."
    cat $persistentVolumeClaimTemplate | 
    yq "(.metadata.name)|="\""$persistentVolumeClaimName"\" |
    yq "(.spec.storageClassName)|="\""$storageClassName"\" |
    kubectl apply -n $namespace -f -
fi

# Check if the pod already exists
result=$(kubectl get pod -n $namespace -o json | jq -r '.items[].metadata.name | select(. == "'$podName'")')

if [[ -n $result ]]; then
    echo "[$podName] pod already exists"
    exit
else
    # Create the pod 
    echo "[$podName] pod does not exist"
    echo "Creating [$podName] pod..."
    cat $podTemplate | 
    yq "(.metadata.name)|="\""$podName"\" |
    yq "(.spec.volumes[0].persistentVolumeClaim.claimName)|="\""$persistentVolumeClaimName"\" |
    kubectl apply -n $namespace -f -
fi