# Apply Developer Namespace (Legacy)

## Run the Script

```shell
./scripts/apply-dev-namespace-legacy.sh
```

## What Did the Script Do?

This script creates a TAP developer namespace called `product-team1` to the Iterate, Build and Run Clusters. To access ACR, a TAP registry secret called `registry-credentials` is created to the namespace `product-team1`. In lieu of a ytt overlay, there is a corresponding [rbac.yaml](../../tap-declarative-yaml/dev-namespace/rbac.yaml) applied to the namespace `product-team1` which allows workloads to be deployed. `rbac.yaml` references the secret `registry-credentials` and contains another secret called `tap-registry` for the service account that is created. The profiles for these clusters will be applied and the script will wait for reconcilation.

```shell
# NOTE: replace [iterate-cluster-name]
kubectl -n product-team1 get secret --kubeconfig ./generated/kubeconfigs/[iterate-cluster-name].yaml
kubectl -n product-team1 get serviceaccount --kubeconfig ./generated/kubeconfigs/[iterate-cluster-name].yaml

# NOTE: replace [build-cluster-name]
kubectl -n product-team1 get secret --kubeconfig ./generated/kubeconfigs/[build-cluster-name].yaml
kubectl -n product-team1 get serviceaccount --kubeconfig ./generated/kubeconfigs/[build-cluster-name].yaml

# NOTE: replace [run-cluster-name]
kubectl -n product-team1 get secret --kubeconfig ./generated/kubeconfigs/[run-cluster-name].yaml
kubectl -n product-team1 get serviceaccount --kubeconfig ./generated/kubeconfigs/[run-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  view_cluster:
    name: view-cluster #! name of the cluster to create
  iterate_cluster:
    name: iterate-cluster #! name of the cluster to create
  build_cluster:
    name: build-cluster #! name of the cluster to create
  run_clusters:
    - name: dev-cluster #! name of the cluster to create
    - name: prod-cluster #! name of the cluster to create
```

## Congrats

The Supply Chain Basic steps are now complete.

## Go to Next Step

[Apply Application Accelerator](../workloads/01-apply-application-accelerator.md)
