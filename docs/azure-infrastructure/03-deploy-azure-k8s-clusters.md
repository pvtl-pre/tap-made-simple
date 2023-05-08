# Deploy Azure Kubernetes Clusters

## Run the Script

```shell
./scripts/03-deploy-azure-k8s-clusters.sh
```

## What Did the Script Do?

This script creates or uses an existing Azure Kubernetes Service (AKS) clusters. You can control of the name of the AKS clusters by setting the value for `clusters.[cluster-type].name`. If any one of them doesn't exist, the script will create it. Once all of them are created, kubeconfigs will be generated and placed in the `generated/kubeconfigs` directory and the paths to them will be stored in `./generated/params.yaml`. Finally, ssh keys will be generated for the AKS clusters if the value for `clusters.ssh_key_path` is not set. Generated keys can be found at `./generated/ssh-key` and `./generated/ssh-key.pub`.

## Values Used From params.yaml

```yaml
clusters:
  ssh_key_path: #! set or it will be automatically set
  view_cluster:
    name: view-cluster #! name of the cluster to create
  iterate_cluster:
    name: iterate-cluster #! name of the cluster to create
  build_cluster:
    name: build-cluster #! name of the cluster to create
  run_clusters:
    - name: dev-cluster #! name of the cluster to create
    - name: prod-cluster #! name of the cluster to create
```

## Go to Next Step

[Download and Install Cluster Essentials](../tap-prereqs/01-download-and-install-cluster-essentials.md)
