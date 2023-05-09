# Apply Build Profile

## Run the Script

```shell
./scripts/apply-build-profile.sh
```

## What Did the Script Do?

This script applies the generated Build profile to the Build Cluster. It does not wait for a successful reconcilation. You can watch as it reconciles with the following command:

```shell
# NOTE: replace [build-cluster-name]
watch tanzu -n tap-install package installed list --kubeconfig ./generated/kubeconfigs/[build-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  build_cluster:
    name: build-cluster #! name of the cluster to create
```

## Go to Next Step

[Apply Run Profiles](./05-apply-run-profiles.md)
