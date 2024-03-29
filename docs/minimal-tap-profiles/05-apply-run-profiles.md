# Apply Run Profiles

## Run the Script

```shell
./scripts/apply-run-profiles.sh
```

## What Did the Script Do?

This script applies the generated Run Profiles to the Run Clusters. It does not wait for a successful reconcilation but can be watched with the following command:

```shell
# NOTE: replace [run-cluster-name]
watch tanzu package installed list -n tap-install --kubeconfig ./generated/kubeconfigs/[run-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  run_clusters:
    - name: dev-cluster #! name of the cluster to create
    - name: prod-cluster #! name of the cluster to create
```

## Go to Next Step

[Apply Iterate Profile](./06-apply-iterate-profile.md)
