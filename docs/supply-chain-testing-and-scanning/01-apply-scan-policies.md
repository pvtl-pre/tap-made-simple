# Apply Scan Policies

This is the first step in changing to the testing and scanning supply chain from the testing one.

## Run the Script

```shell
./scripts/apply-scan-policies.sh
```

## What Did the Script Do?

This script applies a scan policy to the Build Cluster. In lieu of a ytt overlay, there is a corresponding [scan-policy.yaml](../../tap-declarative-yaml/dev-namespace/scan-policy.yaml) applied to the namespace `product-team1`. The policy purposefully comments out severities which generally should not be allowed and instead, allows all vulnerabilities to pass through the pipeline.

```
# notAllowedSeverities := ["Critical", "High", "UnknownSeverity"]
notAllowedSeverities := []
```

```shell
# NOTE: replace [build-cluster-name]
kubectl get scanpolicy -n product-team1 --kubeconfig ./generated/kubeconfigs/[build-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  build_cluster:
    name: build-cluster #! name of the cluster to create
```

## Go to Next Step

[Apply Scanner Access to Store Scan Results](./02-apply-scanner-access-to-store-scan-results.md)
