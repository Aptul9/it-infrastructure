#!/bin/bash

# se --no-check skippiamo la conferma del context corretto
if [[ "$1" != "--no-check" ]]; then
  # Chiediamo conferma
  echo "Sei nel context corretto?"
  kubectl config current-context
  echo "1: Si, 0: NO "
  read -r confirmation

  if [[ "$confirmation" -ne 1 ]]; then
    echo "Controlla il tuo Kubernetes context e riprova."
    exit 1
  fi
fi

# Get pods con deletionTimestamp (terminating pods) o in stato Evicted
PROBLEMATIC_PODS=$(kubectl get pods --all-namespaces -o json | jq '.items[] | select(.metadata.deletionTimestamp != null or .status.phase == "Failed" and .status.reason == "Evicted")')

# Controlliamo ci siano pods in terminating o evicted
POD_COUNT=$(echo "$PROBLEMATIC_PODS" | jq 'length')

# Controlliamo se la lista è vuota
if [[ "$POD_COUNT" -eq 0 ]]; then
  echo "Non ci sono pod in Terminating o Evicted"
  exit 0
fi

echo "Deleting pods in Terminating or Evicted state..."

# Li cancelliamo attraverso lo UID
echo "$PROBLEMATIC_PODS" | jq -r '"\(.metadata.name) \(.metadata.namespace) \(.metadata.uid)"' | while read pod namespace uid; do
  echo "Deleting pod: $pod in namespace: $namespace (UID: $uid)"
  kubectl delete pod "$pod" -n "$namespace" --force --grace-period=0 --wait=false --ignore-not-found=true
done

echo "All terminating and evicted pods deleted."