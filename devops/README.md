# GitLab

  

## GitLab Runners

Our Goal is to set up GitLab and GitLab Runner using a private Certificate Authority (CA) and configure Kubernetes to trust it, without exposing the GitLab instance publicly.

  

1. Generate a Private Certificate Authority (CA)
```
openssl genrsa -aes256 -out cakey.pem 4096
openssl req -x509 -new -nodes -key cakey.pem \
-sha256 -days 3650 \
-subj "/CN=gitlab-devops.pcdacs.local/C=IT/L=roma" \
-out cacert.pem
```
We now have:
```
cakey.pem:  CA's private key
cacert.pem: Self-signed root certificate
```
  
2. Generate Server Key and CSR
```
openssl genrsa -out serverkey.pem 2048
openssl req -new -nodes \
-key serverkey.pem \
-out server.csr \
-subj "/CN=gitlab-devops.pcdacs.local" \
-addext "subjectAltName=DNS:gitlab-devops.pcdacs.local"
```
3. Sign Server Certificate with the CA
```
openssl x509 -req -in server.csr \
-CA cacert.pem -CAkey cakey.pem -CAcreateserial \
-out servercert.pem -days 365 \
-extfile <(printf "subjectAltName=DNS:gitlab-devops.pcdacs.local")
```
We now have:
```
serverkey.pem: Server's private key
servercert.pem: Server certificate signed by your CA
```
4. Create Kubernetes Secrets and ConfigMaps
Create a Configmap to be mounted on the pods

```
kubectl -n gitlab create configmap gitlab-ca-cert --from-file=cacert.pem
```

Create a secret for the ingress:
```
kubectl -n gitlab create secret tls gitlab-tls \
--cert=servercert.pem \
--key=serverkey.pem
```
5. Update the Values of the Helm Chart

For the ingress:
```
global:
  ingress:
    configureCertmanager: false
    class: nginx
    tls:
      enabled: true
      secretName: gitlab-tls
```
And for the runner:
```
gitlab-runner:
  install: true
  volumes:
    - name: gitlab-ca-cert
      configMap:
        name: gitlab-ca-cert

  volumeMounts:
    - name: gitlab-ca-cert
      mountPath: /etc/ssl/certs/cacert.pem
      subPath: cacert.pem
      readOnly: true
```
