helm upgrade -i minio minio-official/minio -f minio-values.yaml --create-namespace --namespace minio-system
# se la release non si chiama velero nel namespace velero si spacca tutto
helm upgrade -i velero vmware-tanzu/velero --create-namespace --namespace velero -f velero-values.yaml
# credenziali di default admin:admin
helm upgrade -i my-velero-ui otwld/velero-ui --namespace velero-ui --create-namespace -f velero-ui-values.yaml