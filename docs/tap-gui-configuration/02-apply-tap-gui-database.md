# Apply TAP GUI Database

## Run the Script

```shell
./scripts/apply-tap-gui-database.sh
```

## What Did the Script Do?

This script creates and binds a Postgres database to TAP GUI for persistent storage. The Postgres container image is pulled from [Bitnami](https://bitnami.com) via a helm chart to a new namespace called `tap-gui-backend`. Since this workshop is not suitable for production use, the database's credentials are hardcoded to `tapuser` for the username and `VMware1!` for the password. The ytt overlay [tap-gui-database.yaml](../../profile-overlays/tap-gui-database.yaml) updates the generated View Profile. The View Profile will be applied and the script will wait for reconcilation.

```shell
# NOTE: replace [view-cluster-name]
kubectl -n tap-gui-backend get po tap-gui-db-postgresql-0 --kubeconfig ./generated/kubeconfigs/[view-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  view_cluster:
    name: view-cluster #! name of the cluster to create
```

## Congrats

The TAP GUI Configuration steps are now complete.

## Go to Next Step

[Apply Supply Chain Basic](../supply-chain-basic/01-apply-supply-chain-basic.md)
