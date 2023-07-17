# Apply Java Workload for Supply Chain Testing

## Run the Script

```shell
./scripts/apply-java-workload-for-supply-chain-testing.sh
```

## What Did the Script Do?

This script applies workload updates to the Build Cluster. The updates consist of adding the label `apps.tanzu.vmware.com/has-tests=true` and multiple param values `"apps.tanzu.vmware.com/language":"java"` and `"apps.tanzu.vmware.com/pipeline":"test"` for the key `testing_pipeline_matching_labels`. Once completed, the Java workload that was previously in an error state will reconcile through the testing supply chain.

This is purposefully not applied to the Iterate Cluster because the sample Java app already contains a [workload.yaml](https://github.com/pvtl-pre/tanzu-java-web-app/blob/main/config/workload.yaml) which contains the changes. Iterating the application uses this file for deployment via the [Tilt file](https://github.com/pvtl-pre/tanzu-java-web-app/blob/main/Tiltfile). When previously using the basic supply chain, these params where ignored while iterating the app.

```shell
# NOTE: replace [build-cluster-name]
tanzu apps workload get tanzu-java-web-app -n product-team1 --kubeconfig ./generated/kubeconfigs/[build-cluster-name].yaml
tanzu apps workload tail tanzu-java-web-app -n product-team1 --kubeconfig ./generated/kubeconfigs/[build-cluster-name].yaml

# NOTE: replace [run-cluster-name]
kubectl get kservice tanzu-java-web-app -n product-team1 --kubeconfig ./generated/kubeconfigs/[run-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  build_cluster:
    name: build-cluster #! name of the cluster to create
```

## Congrats

The Supply Chain Testing steps are now complete.

## Go to Next Step

[Apply Scan Policies](../supply-chain-testing-and-scanning/01-apply-scan-policies.md)
