openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt -subj "/CN=Internal CA"
kubectl create secret tls my-ca-secret --cert=ca.crt --key=ca.key -n cert-manager
