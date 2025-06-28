
# Harbor
To pull Image from a private registry we need Kubernetes-Level Pod Authentication so we will use a standard imagePullSecret in the Kubernetes manifests to provide the credentials needed to authenticate with the registry.

1. Rancher Configuration

Since our registry doesn't have a proper TLS certificate we need to modify the containerd configuration on each RKE2 node to instruct it to skip TLS verification for your specific Harbor registry. This is done via the `/etc/rancher/rke2/registries.yaml` file. Additional documentation can be found [here](https://docs.rke2.io/install/private_registry#without-tls).

This file configures the underlying container runtime (containerd) on each node in your cluster.
We will SSH into each RKE2 server and agent node where workloads might be scheduled.
```
sudo mkdir -p /etc/rancher/rke2/
sudo nano /etc/rancher/rke2/registries.yaml
```

Add the following code:

Generated yaml
```
configs:
  "harbor-devops.pcdacs.local":
    tls:
      insecure_skip_verify: true
    auth:
      username: "admin"
      password: "Harbor12345"
```


Then we will need to restart RKE2 Services

    sudo systemctl restart rke2-agent

2. Kubernetes level configuration

Even with the node-level configuration, we must still provide an imagePullSecret for your pods. This is the standard Kubernetes way to handle authorization for image pulls and follows the principle of least privilege.

Create the Secret:
```
apiVersion: v1
kind: Secret
metadata:
  name: harborpullsecret
  namespace: {{ . }}
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: {{ `{"auths":{"harbor.local":{"username":"admin","password":"Harbor12345"}}}` | b64enc | quote }}
```
Obviously, the secret above needs to be base64 encoded, the example above is a helm template to make it more clear when watching it.
Reference the Secret in a Pod:
```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-harbor
  namespace: default
spec:
  containers:
  - name: nginx
    image: harbor-devops.pcdacs.local/acs-test/nginx:latest
  imagePullSecrets:
  - name: harborpullsecret
```
