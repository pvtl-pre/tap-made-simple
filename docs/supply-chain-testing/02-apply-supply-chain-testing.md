# Apply Supply Chain Testing

## Run the Script

```shell
./scripts/apply-supply-chain-testing.sh
```

## What Did the Script Do?

This script applies a testing supply chain to the Iterate and Build Clusters. The ytt overlay [supply-chain-basic.yaml](../../profile-overlays/supply-chain-testing.yaml) is simplistic and uses no values. The profiles for these clusters will be applied and the script will wait for reconcilation. Once completed, the Java workload that was previously deployed will now be in an error state.

```shell
# NOTE: replace [iterate-cluster-name]
kubectl get clustersupplychains --kubeconfig ./generated/kubeconfigs/[iterate-cluster-name].yaml

# NOTE: replace [build-cluster-name]
kubectl get clustersupplychains --kubeconfig ./generated/kubeconfigs/[build-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  iterate_cluster:
    name: iterate-cluster #! name of the cluster to create
  build_cluster:
    name: build-cluster #! name of the cluster to create
```

## Go to Next Step

[Apply Java Workload for Supply Chain Testing](./03-apply-java-workload-for-supply-chain-testing.md)
