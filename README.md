
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
# Longhorn
To be able to use ReadWriteMany on Longhorn we need to do the following steps:
1. [Install NSF client](https://longhorn.io/docs/1.9.1/deploy/install/#installing-nfsv4-client): 
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.9.1/deploy/prerequisite/longhorn-nfs-installation.yaml
```
Then we will be able to see the NSF pods:
```
kubectl -n longhorn-system get pod | grep longhorn-nfs-installation
NAME                                  READY   STATUS    RESTARTS   AGE
longhorn-nfs-installation-t2v9v   1/1     Running   0          143m
longhorn-nfs-installation-7nphm   1/1     Running   0          143m
```
2. We now need to label our worker nodes:
```
kubectl label node pcd-sv-k8ns-w01 longhorn-role=worker
kubectl label node pcd-sv-k8ns-w02 longhorn-role=worker
kubectl label node pcd-sv-k8ns-w03 longhorn-role=worker
```
3. We can now create the new [StorageClass](https://longhorn.io/docs/1.9.1/nodes-and-volumes/volumes/rwx-volumes/#configuring-volume-locality-for-rwx-volumes):
```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-rwx
provisioner: driver.longhorn.io
parameters:
  shareManagerNodeSelector: longhorn-role:worker
  migratable: "false"
```

4. We can now create the ReadWriteMany PVC and then mount it into the pods:
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: longhorn-rwx-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: longhorn-rwx
  resources:
    requests:
      storage: 1Gi
```

# Domains
Currently the followings are the production exposed hostnames:
- web-pcd.cultura.gov.it
- identity-pcd.cultura.gov.it
- apigw-pcd.cultura.gov.it