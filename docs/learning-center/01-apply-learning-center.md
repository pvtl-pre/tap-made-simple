# Apply Learning Center

This is the only step in setting up Learning Center.

## Run the Script

```shell
./scripts/apply-learning-center.sh
```

## What Did the Script Do?

This script applies learning center to the View Cluster. The ytt overlay [learning-center.yaml](../../profile-overlays/learning-center.yaml) is configured to use the learning center ingress domain. If the View Profile is running a version of Kubernetes greather than 1.25, an additional ytt overlay [learning-center-podsecuritypolicy-fix.yaml](../../profile-overlays/learning-center-podsecuritypolicy-fix.yaml) is configured to indicate the Kubernetes version to TAP. The version indicates that the replacement for Pod Security Policies, called Pod Security Admission, is to be used instead. The View Profile will be applied and the script will wait for reconcilation. Finally, learning center is restarted by deleting the deployment `learningcenter-operator` and trainingportal `learning-center-guided` and forced to reconcile the kapps `learningcenter` and `learningcenter-workshops`. Once completed, learning center should be accessible via the ingress domain.

```shell
# NOTE: replace [view-cluster-name]
kubectl get deployment learningcenter-operator --kubeconfig ./generated/kubeconfigs/[view-cluster-name].yaml

# NOTE: replace [view-cluster-name]
kubectl get trainingportals learning-center-guided --kubeconfig ./generated/kubeconfigs/[view-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  view_cluster:
    name: view-cluster #! name of the cluster to create
    learning_center_ingress_domain: #! set to the ingress domain for the Learning Center component (e.g. learningcenter.example.com)
```

## Congrats

The Learning Center step is now complete.

## Go to Next Step

[Apply Cloud Native Runtimes](../tls/01-apply-cloud-native-runtimes.md)
