# Apply Build Profile

## Run the Script

```shell
./scripts/apply-build-profile.sh
```

## What Did the Script Do?

This script applies the generated Build Profile to the Build Cluster. It does not wait for a successful reconcilation but can be watched with the following command:

```shell
# NOTE: replace [build-cluster-name]
watch tanzu package installed list -n tap-install --kubeconfig ./generated/kubeconfigs/[build-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  build_cluster:
    name: build-cluster #! name of the cluster to create
```

## Go to Next Step

[Apply Run Profiles](./05-apply-run-profiles.md)
