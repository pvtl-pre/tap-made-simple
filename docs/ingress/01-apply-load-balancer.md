# Apply Load Balancer

## Run the Script

```shell
./scripts/apply-load-balancer.sh
```

## What Did the Script Do?

This script adds a load balancer to the Iterate, Run and View Clusters. The ytt overlay [load-balancer.yaml](../../profile-overlays/load-balancer.yaml) is simplistic and uses no values. The profiles for these clusters will be applied and the script will wait for reconcilation.

```shell
kubectl -n tanzu-system-ingress get svc envoy --kubeconfig ./generated/kubeconfigs/[iterate-cluster-name].yaml

kubectl -n tanzu-system-ingress get svc envoy --kubeconfig ./generated/kubeconfigs/[run-cluster-name].yaml

kubectl -n tanzu-system-ingress get svc envoy --kubeconfig ./generated/kubeconfigs/[view-cluster-name].yaml
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

## Go to Next Step

[Configure DNS](./02-configure-dns.md)
