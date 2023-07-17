# Apply Java Workload

## Run the Script

```shell
./scripts/apply-java-workload.sh
```

## What Did the Script Do?

This script applies a workload to the Build Cluster and a deliverable to the Run Clusters. The workload is a [sample Java app](https://github.com/pvtl-pre/tanzu-java-web-app/blob/main/catalog/catalog-info.yaml) that is run through the basic supply chain. The reconcilation process through the supply chain takes a few minutes to run and can be viewed in TAP GUI. Once completed, the FQDN of the workload will become publically accessible.

```shell
# NOTE: replace [build-cluster-name]
tanzu apps workload get tanzu-java-web-app -n product-team1 --kubeconfig ./generated/kubeconfigs/[build-cluster-name].yaml
tanzu apps workload tail tanzu-java-web-app -n product-team1 --kubeconfig ./generated/kubeconfigs/[build-cluster-name].yaml

# NOTE: replace [run-cluster-name]
kubectl get kservice tanzu-java-web-app -n product-team1 --kubeconfig ./generated/kubeconfigs/[run-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  build_cluster:
    name: build-cluster #! name of the cluster to create
  run_clusters:
    - name: dev-cluster #! name of the cluster to create
    - name: prod-cluster #! name of the cluster to create
```

## Congrats

The Workloads steps are now complete.

## Go to Next Step

[Apply Pipelines](../supply-chain-testing/01-apply-pipelines.md)