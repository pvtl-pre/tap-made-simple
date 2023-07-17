# Apply Pipelines

This is the first step in changing to the testing supply chain from the basic one.

## Run the Script

```shell
./scripts/apply-pipelines.sh
```

## What Did the Script Do?

This script applies a Java pipeline to the Iterate and Build Clusters. The [java pipeline](../../tap-declarative-yaml/dev-namespace/java-pipeline.yaml) is applied to the namespace `product-team1` and is configured to run unit tests.

```shell
# NOTE: replace [iterate-cluster-name]
kubectl -n product-team1 get pipeline --kubeconfig ./generated/kubeconfigs/[iterate-cluster-name].yaml

# NOTE: replace [build-cluster-name]
kubectl -n product-team1 get pipeline --kubeconfig ./generated/kubeconfigs/[build-cluster-name].yaml
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

[Apply Supply Chain Testing](./02-apply-supply-chain-testing.md)
