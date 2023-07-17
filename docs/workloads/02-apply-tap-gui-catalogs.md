# Apply TAP GUI Catalogs

## Run the Script

```shell
./scripts/apply-tap-gui-catalogs.sh
```

## What Did the Script Do?

This script applies a list of components to TAP GUI's [software catalog](https://backstage.io/docs/features/software-catalog/). In other words, it statically registers known Git repositories (aka components). The ytt overlay [tap-gui-auth.yaml](../../profile-overlays/tap-gui-auth.yaml) updates the generated View Profile. The View Profile will be applied and the script will wait for reconcilation. Once completed, TAP GUI will contain the registered components.

## Values Used From params.yaml

```yaml
clusters:
  view_cluster:
    name: view-cluster #! name of the cluster to create
tap_gui:
  app_config:
    catalog:
      locations:
        - type: url
          target: https://github.com/pvtl-pre/tap-catalogs/blob/main/yelb-catalog/catalog-info.yaml
        - type: url
          target: https://github.com/pvtl-pre/tanzu-java-web-app/blob/main/catalog/catalog-info.yaml
```

## Go to Next Step

[Apply Application Live View](./03-apply-application-live-view.md)
