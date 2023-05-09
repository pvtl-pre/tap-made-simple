# Allow TAP GUI to View Resources

## Run the Script

```shell
./scripts/allow-tap-gui-to-view-resources.sh
```

## What Did the Script Do?

This script binds the Iterate, Build and Run Clusters to the View Cluster. This allows the View Cluster to have visibility into the other clusters. Of course, visibility is granted by Kubernetes RBAC. The [RBAC](../../tap-declarative-yaml/tap-gui/tap-gui-viewer-service-account-rbac.yaml) also needs a [secret](../../tap-declarative-yaml/tap-gui/tap-gui-viewer-service-account-secret.yaml) for the service account on Kubernetes 1.24+ since it does not get created automatically. Once those are created, the API endpoint and service account token, found in the secret, are extracted and stored in `./generated/params.yaml`. Finally, the ytt overlay [tap-gui-view-resources.yaml](../../profile-overlays/tap-gui-view-resources.yaml) uses these newly extracted values along with the clusters' name to update the generated View Profile. Since this is the first usage of a ytt overlay, it is recommended you take a look at the difference between the [View Profile template](../../profile-templates/view.yaml) and the [generated View Profile](../../generated/profiles) as functionality will be layered on in subsequent steps. The View Profile will be applied and the script will wait for reconcilation.

```shell
# NOTE: replace [view-cluster-name]
watch tanzu -n tap-install package installed list --kubeconfig ./generated/kubeconfigs/[view-cluster-name].yaml
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

[Apply Load Balancer](../ingress/01-apply-load-balancer.md)
