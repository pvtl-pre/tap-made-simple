# Apply Supply Chain Basic

This is the first step in setting up the basic supply chain.

## Run the Script

```shell
./scripts/apply-supply-chain-basic.sh
```

## What Did the Script Do?

This script applies a basic supply chain to the Iterate and Build Clusters. The ytt overlay [supply-chain-basic.yaml](../../profile-overlays/supply-chain-basic.yaml) is simplistic and uses no values. The profiles for these clusters will be applied and the script will wait for reconcilation.

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

[Apply Developer Namespace (Legacy)](./02-apply-dev-namespace-legacy.md)
