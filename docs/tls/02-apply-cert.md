# Apply Certificate

## Run the Script

```shell
./scripts/apply-cert.sh
```

## What Did the Script Do?

This script applies a multi-domain (SAN) wildcard certificate to the View, Iterate and Run Clusters. The certificate is either generated or can be pre-provisioned. Control of which path is taken is by the setting `tls.generate`. If set to `false`, the values `tls.cert_data` (i.e. cert) and `tls.key_data` (i.e. private key) become required and must be base64 encoded. The pre-provisioned certificate must contain wildcards for all of the `ingress_domain` values and it is preferrable to have it signed by a certificate authority. The certificate will be installed in the secret `wildcard` in the namespace `tap-install` on each cluster. It will be [delegated](../../tap-declarative-yaml/tls-delegation.yaml) to all of the other namespaces. The ytt overlay [tls.yaml](../../profile-overlays/tls.yaml) configures TAP GUI, Application Accelerator, Application Live View, Cloud Native Runtimes and Learning Center to utilize this certificate. The profiles for these clusters will be applied and the script will wait for reconcilation. Finally, Learning Center will be restarted.

```shell
# NOTE: replace [view-cluster-name]
kubectl get secret tls wildcard -n tap-install --kubeconfig ./generated/kubeconfigs/[view-cluster-name].yaml
kubectl get tlscertificatedelegation wildcard-delegation -n tap-install --kubeconfig ./generated/kubeconfigs/[view-cluster-name].yaml
kubectl get httpproxy -A --kubeconfig ./generated/kubeconfigs/[view-cluster-name].yaml
kubectl get ingress learningcenter-portal -n learning-center-guided-ui --kubeconfig ./generated/kubeconfigs/[view-cluster-name].yaml

# NOTE: replace [iterate-cluster-name]
kubectl get secret tls wildcard -n tap-install --kubeconfig ./generated/kubeconfigs/[iterate-cluster-name].yaml
kubectl get tlscertificatedelegation wildcard-delegation -n tap-install --kubeconfig ./generated/kubeconfigs/[iterate-cluster-name].yaml
kubectl get httpproxy -A --kubeconfig ./generated/kubeconfigs/[iterate-cluster-name].yaml

# NOTE: replace [run-cluster-name]
kubectl get secret tls wildcard -n tap-install --kubeconfig ./generated/kubeconfigs/[run-cluster-name].yaml
kubectl get tlscertificatedelegation wildcard-delegation -n tap-install --kubeconfig ./generated/kubeconfigs/[run-cluster-name].yaml
kubectl get httpproxy -A --kubeconfig ./generated/kubeconfigs/[run-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  view_cluster:
    name: view-cluster #! name of the cluster to create
    ingress_domain: #! set to the ingress domain for View Cluster components (e.g. tap.example.com)
    learning_center_ingress_domain: #! set to the ingress domain for the Learning Center component (e.g. learningcenter.example.com)
  iterate_cluster:
    name: iterate-cluster #! name of the cluster to create
    ingress_domain: #! set to the ingress domain for iterate ingress objects (e.g. iterate.example.com)
  run_clusters:
    - name: dev-cluster #! name of the cluster to create
      ingress_domain: #! set to the ingress domain for dev ingress objects (e.g. dev.example.com)
    - name: prod-cluster #! name of the cluster to create
      ingress_domain: #! set to the ingress domain for prod ingress objects (e.g. prod.example.com)
tls:
  generate: true #! a self signed cert will be automatically generated
  cert_data: #! cert data for wildcard cert that covers all clusters ingress domains
  key_data: #! key data for wildcard cert that covers all clusters ingress domains
```

## Congrats

The TLS steps are now complete. This marks the final step for the whole deployment!