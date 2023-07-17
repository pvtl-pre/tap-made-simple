# Apply View Profile

## Run the Script

```shell
./scripts/apply-view-profile.sh
```

## What Did the Script Do?

This script applies the generated View Profile to the View Cluster. It does not wait for a successful reconcilation but can be watched with the following command:

```shell
# NOTE: replace [view-cluster-name]
watch tanzu package installed list -n tap-install --kubeconfig ./generated/kubeconfigs/[view-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  view_cluster:
    name: view-cluster #! name of the cluster to create
```

## Go to Next Step

[Apply Build Profile](./04-apply-build-profile.md)
