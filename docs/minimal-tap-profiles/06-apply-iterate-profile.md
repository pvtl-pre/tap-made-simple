# Apply Iterate Profile

## Run the Script

```shell
./scripts/apply-iterate-profile.sh
```

## What Did the Script Do?

This script applies the generated Iterate Profile to the Iterate Cluster. It does not wait for a successful reconcilation but can be watched with the following command:

```shell
# NOTE: replace [iterate-cluster-name]
watch tanzu package installed list -n tap-install --kubeconfig ./generated/kubeconfigs/[iterate-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  iterate_cluster:
    name: iterate-cluster #! name of the cluster to create
```

## Go to Next Step

[Allow TAP GUI to View Resources](./07-allow-tap-gui-to-view-resources.md)
