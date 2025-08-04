#!/bin/bash

SERVICE_ACCOUNT_NAME="developer-user"
NAMESPACE="kube-system"
OUTPUT_FILE="developer-kubeconfig.yaml"
SECRET_NAME="developer-user-token"

SERVER_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CA_DATA=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.ca\.crt}')
TOKEN=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.token}' | base64 --decode)

echo "---
apiVersion: v1
kind: Config
clusters:
- name: ${CLUSTER_NAME}
  cluster:
    server: ${SERVER_URL}
    certificate-authority-data: ${CA_DATA}
contexts:
- name: ${SERVICE_ACCOUNT_NAME}@${CLUSTER_NAME}
  context:
    cluster: ${CLUSTER_NAME}
    user: ${SERVICE_ACCOUNT_NAME}
    namespace: default
users:
- name: ${SERVICE_ACCOUNT_NAME}
  user:
    token: ${TOKEN}
current-context: ${SERVICE_ACCOUNT_NAME}@${CLUSTER_NAME}" > "$OUTPUT_FILE"

echo "Kubeconfig file created successfully."
echo "You can now use it with: kubectl --kubeconfig=${OUTPUT_FILE} get pods -A"