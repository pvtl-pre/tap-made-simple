# Apply TAP GUI Access to Scan Results

## Run the Script

```shell
./scripts/apply-scanner-access-to-store-scan-results.sh
```

## What Did the Script Do?

This script applies TAP GUI access to retrieve scan results to the View Cluster. The scan results are stored in the metadata store. The access token is retrieved from the secret called `metadata-store-read-write-client` in the namespace `metadata-store`. The ytt overlay [tap-gui-metadata-store-auth.yaml](../../profile-overlays/tap-gui-metadata-store-auth.yaml) updates the generated View Profile. The View Profile will be applied and the script will wait for reconcilation.

```shell
# NOTE: replace [view-cluster-name]
kubectl get secret metadata-store-read-write-client -n metadata-store --kubeconfig ./generated/kubeconfigs/[view-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  view_cluster:
    name: view-cluster #! name of the cluster to create
```

## Go to Next Step

[Apply Supply Chain Testing and Scanning](./04-apply-supply-chain-testing-and-scanning.md)
