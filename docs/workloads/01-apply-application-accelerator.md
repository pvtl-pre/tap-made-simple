# Apply Application Accelerator

This is the first step in setting up the submitting of workloads to be processed by the supply chain.

## Run the Script

```shell
./scripts/apply-application-accelerator.sh
```

## What Did the Script Do?

This script applies the application accelerator feature to the View Cluster. It configures application accelerator samples to be included. The ytt overlay [load-balancer.yaml](../../profile-overlays/application-accelerator.yaml) is simplistic and uses no values. The View Profile will be applied and the script will wait for reconcilation. Once completed, TAP GUI will have sample application accelerators in order to start projects.

## Values Used From params.yaml

```yaml
clusters:
  view_cluster:
    name: view-cluster #! name of the cluster to create
```

## Go to Next Step

[Apply TAP GUI Catalogs](./02-apply-tap-gui-catalogs.md)
