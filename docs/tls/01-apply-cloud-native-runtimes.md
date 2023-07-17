# Apply Cloud Native Runtimes

This is the first step in setting up TLS for TAP GUI, Application Accelerator, Application Live View, Cloud Native Runtimes and Learning Center.

## Run the Script

```shell
./scripts/apply-cloud-native-runtimes.sh
```

## What Did the Script Do?

This script applies Cloud Native Runtimes to the Iterate and Run Clusters. The ytt overlay [cloud-native-runtimes.yaml](../../profile-overlays/cloud-native-runtimes.yaml) is configured to use the ingress domain respective to the Iterate and Run Clusters and also changes the hostname used to access deployed workloads. Previously, a workload would be accessible with a subdomain template of `[workload-name].[namespace].[ingress-domin]`. It is reconfigured to remove the dot separator betwen the workload name and namespace in favor of a hypen in order to support wildcard certificates. The profiles for these clusters will be applied and the script will wait for reconcilation. Once completed, `tanzu-java-web-app` workload that was previously deployed will have a new URL which can get obtained with the command below.

```shell
# NOTE: replace [run-cluster-name]
kubectl get kservice tanzu-java-web-app -n product-team1 --kubeconfig ./generated/kubeconfigs/[run-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  iterate_cluster:
    name: iterate-cluster #! name of the cluster to create
    ingress_domain: #! set to the ingress domain for iterate ingress objects (e.g. iterate.example.com)
  run_clusters:
    - name: dev-cluster #! name of the cluster to create
      ingress_domain: #! set to the ingress domain for dev ingress objects (e.g. dev.example.com)
    - name: prod-cluster #! name of the cluster to create
      ingress_domain: #! set to the ingress domain for prod ingress objects (e.g. prod.example.com)
```

## Go to Next Step

[Apply Certificate](./02-apply-cert.md)
