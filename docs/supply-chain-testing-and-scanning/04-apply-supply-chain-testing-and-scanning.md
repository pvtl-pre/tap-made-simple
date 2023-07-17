# Apply Supply Chain Testing and Scanning

## Run the Script

```shell
./scripts/apply-supply-chain-testing-and-scanning.sh
```

## What Did the Script Do?

This script applies a testing and scanning supply chain to the Build Cluster. The ytt overlay [supply-chain-testing-and-scanning.yaml](../../profile-overlays/supply-chain-testing-and-scanning.yaml) is simplistic and uses no values. The Build Profile will be applied and the script will wait for reconcilation. Once completed, TAP GUI will be able to visualize scanning of the code and container image.

```shell
# NOTE: replace [build-cluster-name]
kubectl get clustersupplychains --kubeconfig ./generated/kubeconfigs/[build-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  build_cluster:
    name: build-cluster #! name of the cluster to create
```

## Congrats

The Supply Chain Testing and Scanning steps are now complete.

## Go to Next Step

[Apply Learning Center](../learning-center/01-apply-learning-center.md)
