# Apply Scanner Access to Store Scan Results

## Run the Script

```shell
./scripts/apply-scanner-access-to-store-scan-results.sh
```

## What Did the Script Do?

This script applies the scanner access to store scan results to the Build Cluster. The scan results are stored in the metadata store. An access token called `store-auth-token` and [CA cert](../../tap-declarative-yaml/metadata-store-ca.yaml) called `store-ca-cert` are created on the Build Cluster in a namespace called `metadata-store-secrets`. They are obtained from the View Cluster. Once created, they are [exported](../../tap-declarative-yaml/metadata-store-secrets-export.yaml) to the developer namespace. The ytt overlay [scanner-metadata-store-auth.yaml](../../profile-overlays/scanner-metadata-store-auth.yaml) updates the generated Build Profile. The Build Profile will be applied and the script will wait for reconcilation.

```shell
# NOTE: replace [build-cluster-name]
kubectl get secrets -n metadata-store-secrets --kubeconfig ./generated/kubeconfigs/[build-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  view_cluster:
    name: view-cluster #! name of the cluster to create
    ingress_domain: #! set to the ingress domain for View Cluster components (e.g. tap.example.com)
  build_cluster:
    name: build-cluster #! name of the cluster to create
```

## Go to Next Step

[Apply TAP GUI Access to Scan Results](./03-apply-tap-gui-access-to-scan-results.md)
